#!/usr/bin/env bun
/** CLI: bun evals/selfhost_driver_source.ts --parser-build=<fresh native-build.result.json>
 * Require its corresponding fresh final 75-case native semantic acceptance wrapper,
 * authenticate canonical schema3 storage and typed step closures, then compose root scope.
 * Only import paths and the ten public ABI entries are composed; no parser
 * body, datatype, Request or Kont is rewritten.
 */
import {readFileSync,writeFileSync,realpathSync} from 'node:fs';
import {resolve,dirname,relative,posix} from 'node:path';
import {homedir} from 'node:os';
import {execFileSync} from 'node:child_process';
import {createHash} from 'node:crypto';
const release='4ff8545f19b09b7d2b8ca2303668100eac8efd66';
const repository=resolve(import.meta.dir,'..');
const sha=(text:string|Uint8Array)=>createHash('sha256').update(text).digest('hex');
const object=(value:unknown):Record<string,any>=>{
 if(!value||typeof value!=='object'||Array.isArray(value))throw Error('Expected canonical parser build object');
 return value as Record<string,any>;
};

/** Authenticate the native receipt only. This is not parser/root admission;
 * callers must also require the fresh producer's final semantic acceptance. */
export function authenticateNativeParserReceipt(path:string){
 const inputs=new Map<string,string>();
 const read=(path:string)=>{const real=realpathSync(path),text=readFileSync(real,'utf8');inputs.set(real,text);return text;};
 const parserBuild=realpathSync(path),accepted=object(JSON.parse(read(parserBuild)));
 if(accepted.status!=='JS_GENERATED_NOT_YET_EXECUTED'||accepted.checksExcluded!==0||accepted.outputPatches!==0
  ||!Array.isArray(accepted.exports)||accepted.exports.length!==1||accepted.exports[0]!=='parse_with_fuel')throw Error('Complete canonical parser build required');
 if(typeof accepted.provenancePath!=='string')throw Error('Missing canonical parser provenance');
 const provenancePath=realpathSync(accepted.provenancePath),record=object(JSON.parse(read(provenancePath)));
 const {provenanceSha256,...proof}=record;
 if(proof.schemaVersion!==4||provenanceSha256!==accepted.provenanceSha256||sha(JSON.stringify(proof))!==provenanceSha256)
  throw Error('Canonical parser provenance hash/version mismatch');
 const protectedPins=object(proof.protectedPins),loadedInputs=object(proof.loadedInputs);
 for(const pins of [protectedPins,loadedInputs]){
  if(!Object.keys(pins).length)throw Error('Missing complete canonical parser input manifest');
  for(const [path,digest]of Object.entries(pins))if(resolve(path)!==path||realpathSync(path)!==path
   ||typeof digest!=='string'||!/^[0-9a-f]{64}$/.test(digest)||sha(read(path))!==digest)throw Error('Fresh parser build input drift: '+path);
 }
 for(const [field,path]of [['runnerPath','evals/checker_core_component_build.ts'],['compilerPath','bend2/comp.ts'],
  ['kernelPath','bend2/bend.ts'],['basePath','bend2/base.bend']] as const){
  const current=realpathSync(resolve(repository,path)),digest=sha(read(current));
  if(typeof proof[field]!=='string'||realpathSync(proof[field])!==current||proof[field.replace('Path','Sha256')]!==digest
   ||protectedPins[current]!==digest)throw Error('Canonical release parser producer drift: '+field);
 }
 const kernel=realpathSync(resolve(repository,'bend2/bend.ts'));
 const officialKernelSha256=sha(execFileSync('git',['show',release+':bend2/bend.ts'],{cwd:repository}));
 if(sha(read(kernel))!==officialKernelSha256)throw Error('Kernel differs from exact official release Git blob '+release);
 for(const path of ['evals/heavy_gate.ts','evals/heavy_gate_native.c']){
  const current=realpathSync(resolve(repository,path));
  if(protectedPins[current]!==sha(read(current)))throw Error('Missing authenticated canonical parser helper '+path);
 }
 if(typeof accepted.sourcePath!=='string'||typeof accepted.artifactPath!=='string')throw Error('Missing canonical parser source/artifact');
 const parserSource=realpathSync(accepted.sourcePath),source=read(parserSource);
 if(sha(source)!==accepted.sourceSha256||proof.sourcePath!==accepted.sourcePath||proof.sourceSha256!==accepted.sourceSha256
  ||loadedInputs[parserSource]!==accepted.sourceSha256||sha(read(accepted.artifactPath))!==accepted.artifactSha256
  ||JSON.stringify(proof.exports)!==JSON.stringify(accepted.exports)||proof.checksExcluded!==0||proof.outputPatches!==0)
  throw Error('Canonical parser candidate/artifact proof drift');
 const runtime=object(proof.runtime),guard=object(proof.guard),guardian=object(accepted.guardian),observation=object(proof.kernelObservation);
 if(runtime.name!=='node'||runtime.heapLimitMiB!==3072||runtime.stackSizeMb!==256||runtime.manualGC!==false||JSON.stringify(runtime)!==JSON.stringify(accepted.runtime)
  ||guard.memoryMiB!==8192||guard.rssMiB!==8192||guard.pollMs!==10||guardian.status!=='PASS'
  ||guardian.memoryLimitBytes!==8192*1024*1024||guardian.rssLimitBytes!==8192*1024*1024
  ||observation.kernelUnmodified!==true||observation.sourceValueReplacement!==false||observation.parserSubstitutions!==0
  ||proof.loadMode!=='CANONICAL_NATIVE_UNMODIFIED'||proof.checkedOutputRetention!=='native e'||accepted.checkedOutputRetention!=='native e')
  throw Error('Canonical parser native validation/guardian contract drift');
 const bodies=proof.checkedDefinitions;
 if(!Number.isSafeInteger(bodies)||bodies<=0)throw Error('Missing canonical native checked bodies');
 for(const field of ['checkedDefinitions','nativeCheckedBodies','expectedSourceDefinitions'])
  if(proof[field]!==bodies||accepted[field]!==bodies)throw Error('Incomplete canonical native body coverage: '+field);
 if(proof.eventsFullyValidated!==accepted.eventsFullyValidated||!Number.isSafeInteger(proof.eventsFullyValidated)
  ||proof.eventsFullyValidated<=0)throw Error('Incomplete canonical native validation events');
 // Independently close the actual import headers; a self-consistent but partial
 // input map must not authenticate an unobserved transitive .bend provider.
 const closure=new Set<string>(),library=resolve(process.env.BEND_LIB??posix.join(homedir(),'.bend','lib'));
 function visit(path:string){
  const real=realpathSync(path);if(closure.has(real))return;closure.add(real);
  const text=read(real);if(loadedInputs[real]!==sha(text))throw Error('Unobserved parser source dependency '+real);
  for(const raw of text.split('\n')){
   const line=raw.trim();if(!line||line.startsWith('#'))continue;
   if(!/^import(\s|$)/.test(line))break;
   const imported=/^import\s+(\S+)(?:\s+as\s+([A-Za-z_]\w*))?\s*(?:#.*)?$/.exec(line);
   if(!imported||(imported[2]===undefined&&imported[1]!=='Base'))throw Error('Parser import manifest drift: '+real);
   const target=imported[1]!;
   if(target.includes('@'))throw Error('Parser receipt requires resolved immutable Hub import '+target);
   visit(imported[2]===undefined?resolve(repository,'bend2/base.bend'):
    /^0x[0-9a-f]+\//.test(target)?resolve(library,target):resolve(dirname(real),target));
  }
 }
 visit(parserSource);
 if(Object.keys(loadedInputs).filter(path=>path.endsWith('.bend')).sort().join('\n')!==[...closure].sort().join('\n'))
  throw Error('Canonical parser complete loaded source closure drift');
 for(const [path,text]of inputs)if(readFileSync(path,'utf8')!==text)throw Error('Parser proof input changed during authentication: '+path);
 return {accepted,proof,parserBuild,provenancePath,parserSource,source,officialKernelSha256,
  authenticatedInputs:Object.fromEntries([...inputs].map(([path,text])=>[path,sha(text)]))};
}

/** Complete semantic evidence authentication, without authorizing root use. */
export function authenticateParserSemanticGate(path:string,options:{
 phase:'source'|'candidate';parserPath:string;canonicalSha256:string;kernelSha256:string;
 component?:{artifactPath:string;nativeBuildPath:string};
}){
 const inputs=new Map<string,string>();
 const read=(path:string)=>{const real=realpathSync(path),text=readFileSync(real,'utf8');inputs.set(real,text);return text;};
 const reportPath=realpathSync(path),report=object(JSON.parse(read(reportPath)));
 const parserPath=realpathSync(options.parserPath),parserSha256=sha(read(parserPath));
 const sourcePhase=options.phase==='source',evaluationMode=sourcePhase?'source-preparation':'native-artifact';
 const entryPoint=sourcePhase?'parse_module_tokens':'parse_with_fuel';
 const limited=['.parser_definition_body_shape_generated_fuel.bend','base.bend','checker_core_slice.bend','js_emit.bend'];
 const bounded=['checker_core_driver.bend','loaded_module.bend','ast.bend','lexer.bend','core.bend','path.bend'];
 const same=(a:unknown,b:readonly string[])=>Array.isArray(a)&&a.every(x=>typeof x==='string')&&
  JSON.stringify([...a].sort())===JSON.stringify([...b].sort());
 if(report.schemaVersion!==1||report.completed!==true||report.partial!==false||
  realpathSync(report.parserPath)!==parserPath||report.parserSha256!==parserSha256||
  report.canonicalSha256!==options.canonicalSha256||report.entryPoint!==entryPoint||
  report.evaluationMode!==evaluationMode||report.admitted!==!sourcePhase||report.preparationAdmitted!==sourcePhase||
  !same(report.knownEvaluatorLimitedModules,sourcePhase?limited:[])||
  report.kernelSha256!==options.kernelSha256||realpathSync(report.kernelPath)!==realpathSync(resolve(repository,'bend2/bend.ts'))||
  report.sourceSpecificExceptions!==0||report.checksExcluded!==0||report.outputPatches!==0)
  throw Error('Incomplete or mismatched '+evaluationMode+' parser proof');
 const guard=object(report.guard);
 if(guard.memoryMiB!==8192||guard.rssMiB!==8192||guard.pollMs!==10)throw Error('Semantic guardian configuration drift');
 const expected:Record<string,number>={focused:23,whole29:29,literals:13,real:sourcePhase?6:10};
 if(!Array.isArray(report.rows)||report.rows.length!==(sourcePhase?71:75))throw Error('Incomplete parser semantic rows');
 for(const [suite,total]of Object.entries(expected)){
  const rows=report.rows.filter((row:any)=>row.suite===suite),count=object(report.counts?.[suite]);
  if(rows.length!==total||new Set(rows.map((row:any)=>row.name)).size!==total||
   count.total!==total||count.acceptanceParity!==total||count.semanticParity!==total||
   rows.some((row:any)=>typeof row.name!=='string'||row.acceptanceParity!==true||row.semanticParity!==true||
    row.literalSpanParity!==true||row.error!==undefined||row.evaluationMode!==evaluationMode))
   throw Error('Incomplete semantic/literal-span parser suite '+suite);
 }
 if(!same(report.rows.filter((row:any)=>row.suite==='real').map((row:any)=>row.name),sourcePhase?bounded:[...limited,...bounded]))
  throw Error('Incomplete current real-module role coverage');
 if(!Array.isArray(report.sourceInputs)||!report.sourceInputs.length)throw Error('Missing semantic current input closure');
 const currentInputs=new Map<string,string>();
 for(const input of report.sourceInputs){
  if(typeof input.file!=='string'||typeof input.sha256!=='string'||!/^[0-9a-f]{64}$/.test(input.sha256)||
   realpathSync(input.file)!==input.file||currentInputs.has(input.file)||sha(read(input.file))!==input.sha256)
   throw Error('Semantic current input drift');
  currentInputs.set(input.file,input.sha256);
 }
 const inventoryPath=resolve(repository,'checkpoints/bootstrap-real-source-corpus.json');
 const inventory=object(JSON.parse(read(inventoryPath)));
 const migrations=report.realSourceRoleMigrations;
 if(!Array.isArray(inventory.modules)||inventory.modules.length!==10||!Array.isArray(migrations)||migrations.length!==10||
  new Set(migrations.map((row:any)=>row.role)).size!==10)throw Error('Missing current compiler role migration inventory');
 for(const module of inventory.modules){
  const role=module.file.split('/').at(-1),migration=migrations.find((row:any)=>row.role===role);
  const actual=role==='.parser_definition_body_shape_generated_fuel.bend'?parserPath:
   role==='checker_core_slice.bend'?resolve(repository,'checkpoints/checker_core_owned_v1.bend'):
   role==='checker_core_driver.bend'?resolve(repository,'checkpoints/checker_core_owned_driver_v1.bend'):realpathSync(module.file);
  if(!migration||migration.historicalFile!==module.file||realpathSync(migration.file)!==actual||
   migration.sourceSha256!==sha(read(actual))||currentInputs.get(actual)!==migration.sourceSha256)
   throw Error('Current compiler role/path/hash migration drift: '+role);
  const corpus=report.corpus?.filter((row:any)=>row.suite==='real'&&row.name===role);
  if(!Array.isArray(corpus)||corpus.length!==1||realpathSync(corpus[0].file)!==actual||
   corpus[0].sourceSha256!==migration.sourceSha256||corpus[0].historicalFile!==module.file||corpus[0].role!==role)
   throw Error('Current compiler corpus source drift: '+role);
  const row=report.rows.find((row:any)=>row.suite==='real'&&row.name===role);
  if(row&&(realpathSync(row.file)!==actual||row.role!==role||row.historicalFile!==module.file))
   throw Error('Real-module row checked an obsolete compiler role: '+role);
 }
 const regression=object(report.publicRegressions),publicPath=realpathSync(regression.reportPath);
 const publicText=read(publicPath),publicReport=object(JSON.parse(publicText));
 if(regression.parserSha256!==parserSha256||regression.passed!==15||regression.assertions!==264||
  regression.failed!==0||sha(publicText)!==regression.reportSha256||
  publicReport.parserSha256!==parserSha256||publicReport.passed!==15||publicReport.assertions!==264||
  publicReport.failed!==0||publicReport.exitCode!==0||realpathSync(publicReport.parserPath)!==parserPath||
  publicReport.entryPoint!==entryPoint||publicReport.canonicalSha256!==options.canonicalSha256||
  typeof publicReport.rawOutputPath!=='string'||sha(read(publicReport.rawOutputPath))!==publicReport.rawOutputSha256)
  throw Error('Missing parser-bound public regression/raw proof');
 const required=[parserPath,resolve(repository,'bend2/selfhost/parser.bend'),resolve(repository,'bend2/bend.ts'),
  inventoryPath,publicPath,realpathSync(publicReport.rawOutputPath),
  ...['evals/bootstrap_parser_fast.ts','evals/bootstrap_parser_public_gate.ts','evals/heavy_gate.ts','evals/heavy_gate_native.c']
   .map(path=>resolve(repository,path))];
 let component:Record<string,any>|undefined;
 if(!sourcePhase){
  if(!options.component)throw Error('Native artifact semantic proof requires canonical component identity');
  component=object(report.component);
  const native=authenticateNativeParserReceipt(options.component.nativeBuildPath);
  if(realpathSync(component.nativeBuildPath)!==native.parserBuild||
   component.nativeBuildSha256!==sha(read(native.parserBuild))||
   realpathSync(component.artifactPath)!==realpathSync(options.component.artifactPath)||
   native.accepted.artifactPath!==options.component.artifactPath||component.artifactSha256!==native.accepted.artifactSha256||
   native.parserSource!==parserPath||native.accepted.sourceSha256!==parserSha256||
   realpathSync(component.provenancePath)!==native.provenancePath||component.provenanceSha256!==native.accepted.provenanceSha256)
   throw Error('Compiled semantic gate differs from authentic native artifact/receipt/provenance');
  const workerPath=resolve(repository,'evals/bootstrap_parser_native_semantic_worker.mjs');
  const worker=object(report.nativeWorker),runtime=object(worker.runtime);
  if(realpathSync(worker.path)!==realpathSync(workerPath)||worker.sha256!==sha(read(workerPath))||
   runtime.name!=='node'||runtime.heapLimitMiB!==3072||runtime.stackSizeMiB!==256||runtime.manualGC!==false||
   worker.fuelCells!==2000000||worker.transport!=='bend-native-ast-v1'||
   report.rows.some((row:any)=>row.compiledExecution!==true||row.componentArtifactSha256!==component!.artifactSha256||
    typeof row.nativeTransportSha256!=='string'||!/^[0-9a-f]{64}$/.test(row.nativeTransportSha256)||
    !Number.isSafeInteger(row.nativeTransportBytes)||row.nativeTransportBytes<=0))
   throw Error('Missing actual all-row native compiled parser execution/transport evidence');
  for(const [file,digest]of Object.entries(native.authenticatedInputs)){
   const text=read(file);if(sha(text)!==digest)throw Error('Native semantic input changed');
  }
  required.push(native.parserBuild,realpathSync(component.artifactPath),native.provenancePath,
   workerPath,resolve(repository,'evals/bootstrap_ast_transport.ts'));
 }
 for(const file of required)if(currentInputs.get(realpathSync(file))!==sha(read(file)))
  throw Error('Missing authenticated semantic input '+file);
 for(const [file,text]of inputs)if(readFileSync(file,'utf8')!==text)throw Error('Semantic input changed during authentication: '+file);
 return {path:reportPath,sha256:sha(read(reportPath)),phase:options.phase,evaluationMode,rows:report.rows.length,
  parserSha256,entryPoint,publicRegressionPath:publicPath,publicRegressionSha256:regression.reportSha256,
  publicRawOutputPath:realpathSync(publicReport.rawOutputPath),publicRawOutputSha256:publicReport.rawOutputSha256,
  ...(component?{component}:{}),authenticatedInputs:Object.fromEntries([...inputs].map(([path,text])=>[path,sha(text)]))};
}

/** A raw native receipt is provisional until the same fresh producer namespace
 * publishes the complete 75-case compiled semantic acceptance wrapper. */
export function readAcceptedParserBuild(path:string){
 const native=authenticateNativeParserReceipt(path),{accepted,parserBuild,parserSource,officialKernelSha256}=native;
 const suffix='.native-build.result.json';
 if(!parserBuild.endsWith(suffix))throw Error('Final canonical parser producer namespace required');
 const stem=parserBuild.slice(0,-suffix.length),wrapperPath=stem+'.result.json';
 const inputs:Record<string,string>={...native.authenticatedInputs};
 const read=(path:string)=>{
  const real=realpathSync(path),text=readFileSync(real,'utf8'),digest=sha(text);
  if(inputs[real]!==undefined&&inputs[real]!==digest)throw Error('Parser acceptance input changed: '+real);
  inputs[real]=digest;return text;
 };
 const wrapper=object(JSON.parse(read(wrapperPath))),canonicalPath=resolve(repository,'bend2/selfhost/parser.bend');
 const canonicalSha256=sha(read(canonicalPath));
 if(wrapper.schemaVersion!==1||wrapper.status!=='PARSER_ACCEPTED_NATIVE_SEMANTICS'||wrapper.admitted!==true||
  wrapper.preparationAdmitted!==false||wrapper.evaluationMode!=='native-artifact'||
  wrapper.compiledExecution!=='FULL_75_SEMANTIC_GATE'||wrapper.checksExcluded!==0||wrapper.outputPatches!==0||
  wrapper.release!==release||wrapper.releaseKernelSha256!==officialKernelSha256||
  wrapper.canonicalSha256!==canonicalSha256||!/^[A-Za-z0-9][A-Za-z0-9_-]{0,79}$/.test(wrapper.runId)||
  stem!==resolve(repository,'checkpoints/bootstrap-parser-rebuild-'+wrapper.runId)||
  wrapper.parserBuildPath!==parserBuild||wrapper.parserBuildSha256!==sha(read(parserBuild))||
  wrapper.sourceCandidate!==parserSource||wrapper.candidateSha256!==accepted.sourceSha256||
  wrapper.artifactPath!==accepted.artifactPath||wrapper.artifactSha256!==accepted.artifactSha256||
  wrapper.provenancePath!==native.provenancePath||wrapper.provenanceSha256!==accepted.provenanceSha256)
  throw Error('Fresh complete parser acceptance wrapper required; provisional receipt cannot authorize a root');
 const runnerPath=realpathSync(resolve(repository,'evals/bootstrap_parser_rebuild.ts'));
 if(wrapper.runnerSha256!==sha(read(runnerPath)))throw Error('Final parser acceptance producer drift');
 const acceptedInputs=object(wrapper.acceptedInputs),authenticatedInputs=object(wrapper.authenticatedInputs);
 if(!Object.keys(acceptedInputs).length||!Object.keys(authenticatedInputs).length||
  acceptedInputs['evals/bootstrap_parser_rebuild.ts']!==wrapper.runnerSha256||
  acceptedInputs['evals/selfhost_driver_source.ts']!==sha(read(import.meta.path)))
  throw Error('Missing final parser producer/helper closure');
 for(const [file,digest]of Object.entries(acceptedInputs)){
  if(file.startsWith('/')||file.startsWith('..')||typeof digest!=='string'||sha(read(resolve(repository,file)))!==digest)
   throw Error('Final parser producer input drift: '+file);
 }
 for(const [file,digest]of Object.entries(authenticatedInputs)){
  if(resolve(file)!==file||realpathSync(file)!==file||typeof digest!=='string'||sha(read(file))!==digest)
   throw Error('Final parser acceptance proof input drift: '+file);
 }
 const guard=object(wrapper.guard);
 if(guard.memoryMiB!==8192||guard.rssMiB!==8192||guard.pollMs!==10)throw Error('Final parser guardian configuration drift');
 for(const [field,suffix]of [['authorization','.acceptance-authorized.json'],['guardian','.build.guardian.json'],
  ['request','.build.request.json'],['workerLog','.build.jsonl'],['nativeProof','.native-auth.json'],
  ['manifest','.prepare.json'],['sourceManifest','.source-v1.json']] as const){
  if(wrapper[field+'Path']!==stem+suffix||wrapper[field+'Sha256']!==sha(read(stem+suffix)))
   throw Error('Final parser producer evidence drift: '+field);
 }
 const authorization=object(JSON.parse(read(wrapper.authorizationPath)));
 for(const [field,value]of Object.entries(authorization))
  if(JSON.stringify(wrapper[field])!==JSON.stringify(value))throw Error('Final parser authorization differs from wrapper: '+field);
 const proofFields=['node','release','releaseKernelSha256','acceptedInputs','baselineScorecardSha256','runnerSha256','canonicalSha256','guard'];
 for(const phase of ['prepare-source','prepare','build-native','build']){
  const guardian=object(JSON.parse(read(stem+'.'+phase+'.guardian.json')));
  if(guardian.status!=='PASS'||guardian.memoryLimitBytes!==8192*1024*1024||
   guardian.rssLimitBytes!==8192*1024*1024||guardian.pollMs!==10)throw Error('Missing complete parser guardian '+phase);
  const request=object(JSON.parse(read(stem+'.'+phase+'.request.json')));
  for(const field of proofFields)if(JSON.stringify(request[field])!==JSON.stringify(wrapper[field]))
   throw Error('Fresh parser phase request/producer drift: '+phase+'/'+field);
 }
 const events=read(wrapper.workerLogPath).trim().split('\n').map(line=>object(JSON.parse(line)));
 if(!events.some(event=>event.stage==='complete-native-parser-acceptance-authorized'&&event.rows===75&&event.parserBuildPath===parserBuild))
  throw Error('Missing fresh complete native parser acceptance event');
 const manifest=object(JSON.parse(read(wrapper.manifestPath))),sourceManifest=object(JSON.parse(read(wrapper.sourceManifestPath)));
 if(manifest.schemaVersion!==1||manifest.status!=='PREPARED_NOT_BUILT'||manifest.runId!==wrapper.runId||
  sourceManifest.schemaVersion!==1||sourceManifest.status!=='FACTORED_AWAITING_SEMANTIC_GATE'||
  sourceManifest.runId!==wrapper.runId||manifest.candidatePath!==parserSource||
  manifest.candidateSha256!==accepted.sourceSha256||manifest.artifactPath!==accepted.artifactPath||
  manifest.sourceManifestPath!==wrapper.sourceManifestPath||manifest.sourceManifestSha256!==wrapper.sourceManifestSha256||
  sourceManifest.sourcePath!==manifest.sourcePath||sourceManifest.transformedSha256!==manifest.transformedSha256)
  throw Error('Final parser prepared source namespace drift');
 for(const phaseManifest of [manifest,sourceManifest])
  if(phaseManifest.canonicalSha256!==canonicalSha256||phaseManifest.runnerSha256!==wrapper.runnerSha256||
   JSON.stringify(phaseManifest.acceptedInputs)!==JSON.stringify(acceptedInputs))
   throw Error('Prepared parser producer closure drift');
 for(const [file,digest]of [[manifest.sourcePath,manifest.transformedSha256],[manifest.candidatePath,manifest.candidateSha256],
  [manifest.graphPath,manifest.graphSha256],[manifest.overlayPath,manifest.overlaySha256],
  [manifest.architecturePath,manifest.architectureSha256],[manifest.scorecardPath,manifest.scorecardSha256]])
  if(typeof file!=='string'||sha(read(file))!==digest||authenticatedInputs[realpathSync(file)]!==digest)
   throw Error('Final parser prepared input drift: '+file);
 const sourceGate=authenticateParserSemanticGate(wrapper.sourceSemanticGate.path,{phase:'source',
  parserPath:manifest.sourcePath,canonicalSha256,kernelSha256:officialKernelSha256});
 const candidateGate=authenticateParserSemanticGate(wrapper.candidateSemanticGate.path,{phase:'candidate',
  parserPath:parserSource,canonicalSha256,kernelSha256:officialKernelSha256,
  component:{artifactPath:accepted.artifactPath,nativeBuildPath:parserBuild}});
 if(JSON.stringify(sourceGate)!==JSON.stringify(wrapper.sourceSemanticGate)||
  JSON.stringify(sourceGate)!==JSON.stringify(manifest.sourceSemanticGate)||
  JSON.stringify(candidateGate)!==JSON.stringify(wrapper.candidateSemanticGate)||
  JSON.stringify(wrapper.structuralGate)!==JSON.stringify(manifest.structuralGate)||
  wrapper.structuralGate.candidateSha256!==accepted.sourceSha256||wrapper.structuralGate.unresolvedReferences!==0||
  wrapper.structuralGate.selectedCallsUnderLambda!==0||!Array.isArray(wrapper.structuralGate.remainingMutualSCCs)||
  wrapper.structuralGate.remainingMutualSCCs.length!==0)
  throw Error('Final parser preparation/compiled gate changed after acceptance');
 const provisional=object(JSON.parse(read(wrapper.nativeProofPath)));
 if(provisional.schemaVersion!==1||provisional.status!=='PROVISIONAL_NATIVE_ARTIFACT'||provisional.admitted!==false||
  provisional.runId!==wrapper.runId||provisional.parserBuildPath!==parserBuild||
  provisional.parserBuildSha256!==wrapper.parserBuildSha256||provisional.artifactPath!==wrapper.artifactPath||
  provisional.artifactSha256!==wrapper.artifactSha256||provisional.provenancePath!==wrapper.provenancePath||
  provisional.provenanceSha256!==wrapper.provenanceSha256||provisional.manifestSha256!==wrapper.manifestSha256||
  JSON.stringify(provisional.sourceSemanticGate)!==JSON.stringify(sourceGate)||
  JSON.stringify(provisional.structuralGate)!==JSON.stringify(wrapper.structuralGate))
  throw Error('Final parser acceptance changed the provisional native artifact/proofs');
 for(const [field,suffix]of [['authorization','.native-build-authorized.json'],['guardian','.build-native.guardian.json'],
  ['request','.build-native.request.json'],['workerLog','.build-native.jsonl']] as const){
  const file=stem+suffix;
  if(provisional[field+'Path']!==file||provisional[field+'Sha256']!==sha(read(file))||
   authenticatedInputs[realpathSync(file)]!==sha(read(file)))throw Error('Provisional native producer evidence drift: '+field);
 }
 const started=object(JSON.parse(read(stem+'.native-build.started.json')));
 const nativeAuthorization=object(JSON.parse(read(provisional.authorizationPath)));
 const command=[process.execPath,'--smol',resolve(repository,'evals/checker_core_component_build.ts'),
  '--file='+parserSource,'--exports=parse_with_fuel','--artifact='+accepted.artifactPath,'--report='+stem+'.native-build'];
 if(started.onceOnly!==true||started.canonicalSha256!==canonicalSha256||started.candidateSha256!==accepted.sourceSha256||
  nativeAuthorization.parserBuildPath!==parserBuild||nativeAuthorization.candidateSha256!==accepted.sourceSha256||
  nativeAuthorization.manifestPath!==wrapper.manifestPath||nativeAuthorization.manifestSha256!==wrapper.manifestSha256||
  JSON.stringify(nativeAuthorization.command)!==JSON.stringify(command)||
  JSON.stringify(nativeAuthorization.authenticatedInputs)!==JSON.stringify(provisional.authenticatedInputs)||
  JSON.stringify(nativeAuthorization.sourceSemanticGate)!==JSON.stringify(sourceGate)||
  JSON.stringify(nativeAuthorization.structuralGate)!==JSON.stringify(wrapper.structuralGate))
  throw Error('Missing once-only authentic canonical native codegen authorization');
 for(const [file,digest]of Object.entries({...object(provisional.authenticatedInputs),...native.authenticatedInputs,
  ...sourceGate.authenticatedInputs,...candidateGate.authenticatedInputs})){
  if(authenticatedInputs[file]!==digest||sha(read(file))!==digest)throw Error('Incomplete final parser authenticated proof closure: '+file);
 }
 for(const [file,digest]of Object.entries(inputs))if(sha(readFileSync(file))!==digest)throw Error('Parser acceptance input changed during authentication: '+file);
 return {...native,acceptance:wrapper,acceptancePath:realpathSync(wrapperPath),authenticatedInputs:inputs};
}

export function assembleSelfhostDriver(parserBuild:string){
const output='checkpoints/.bootstrap_compiler_root_v1.bend';
const manifest='checkpoints/selfhost-steps-driver-source-v1.json';
const authenticated=readAcceptedParserBuild(parserBuild);
const {parserSource,source}=authenticated;
const typedStepInputs:Record<string,string>={};
for(const [mode,stem]of [['template','template'],['checker','checker-core'],['emitter','js-emit']] as const){
 const path=realpathSync(resolve('checkpoints/'+stem+'-steps-v1.json')),text=readFileSync(path,'utf8');
 const record=object(JSON.parse(text)),{generationManifestSha256,...proof}=record;
 if(generationManifestSha256!==sha(JSON.stringify(proof))||record.generationConfig?.mode!==mode
  ||record.exactCanonicalCoverage!==true||record.residualSourceCalls!==0||record.recursiveHelpers!==1
  ||record.generatedPrivateRecursiveHelpers!==0||record.progressABI!=='typed-native-stack-v57t'
  ||record.nativeChunk?.function!==mode+'_chunk'||record.nativeChunk?.rawStep!==mode+'_step_one'
  ||record.nativeChunk?.publicStep!==mode+'_step'||record.nativeChunk?.start!==mode+'_start'
  ||record.nativeChunk?.quantum!==64||record.nativeChunk?.fuelType!=='Nat'||record.nativeChunk?.recursion!=='structural Nat'
  ||record.nativeChunk?.zeroFuel!=='return remaining Run unchanged'||record.nativeChunk?.semanticFuelChanged!==false
  ||record.nativeChunk?.castBoxFunction!==mode+'_cast_box'||record.nativeChunk?.popFunction!==mode+'_pop'
  ||record.nativeChunk?.advanceFunction!==mode+'_advance'||record.nativeChunk?.exportedResume!==false
  ||record.nativeChunk?.publicStepType!=='-R: Type, Run<R> -> Run<R>'
  ||record.nativeChunk?.sourceResumeClosuresUnchanged!==true||record.nativeChunk?.directInvokeUnchanged!==true
  ||JSON.stringify(record.nativeChunk?.selfRecursiveFunctions)!==JSON.stringify([mode+'_chunk'])
  ||['runType','runFinishedConstructor','runStateConstructor','stackType','stackDoneConstructor','stackMoreConstructor'].some((key,index)=>
    record.nativeChunk?.[key]!==({checker:'Checker',emitter:'Emitter',template:'Template'}[mode])+['Run','RunFinished','RunState','Stack','StackDone','StackMore'][index])
  ||!Array.isArray(record.excludedDefinitions)||record.excludedDefinitions.length
  ||!Array.isArray(record.omittedDefinitions)||record.omittedDefinitions.length)
  throw Error('Complete current typed '+mode+' source generation proof required');
 typedStepInputs[path]=sha(text);
 const hashes=object(record.protectedUnchangedHashes),realpaths=object(record.generationInputRealpaths),outputs=object(record.outputs);
 if(!Object.keys(hashes).length||Object.keys(hashes).sort().join('\n')!==Object.keys(realpaths).sort().join('\n'))
  throw Error('Missing complete typed '+mode+' input closure');
 for(const [input,digest]of Object.entries(hashes)){
  if(realpathSync(input)!==realpaths[input]||sha(readFileSync(input))!==digest)throw Error('Typed '+mode+' source input drift: '+input);
  typedStepInputs[realpathSync(input)]=digest;
 }
 const producer=mode==='template'?'evals/template_step_lower.ts':mode==='checker'?'evals/checker_core_step_lower.ts':'evals/js_emit_step_lower.ts';
 const output=mode==='template'?'checkpoints/template_steps_v1.bend':mode==='checker'?'checkpoints/checker_core_steps_v1.bend':'checkpoints/js_emit_steps_v1.bend';
 if(record.generationConfig.generator!==producer||hashes[producer]!==sha(readFileSync(producer))
  ||outputs[output]===undefined)throw Error('Typed '+mode+' canonical producer/output identity drift');
 for(const [output,digest]of Object.entries(outputs)){
  if(sha(readFileSync(output))!==digest)throw Error('Typed '+mode+' output drift: '+output);
  typedStepInputs[realpathSync(output)]=digest;
 }
 if(mode==='checker'&&!record.coverage?.some((row:any)=>row.name==='inspect_checked'))
  throw Error('Missing owner-preserving checked inspection closure');
 if(mode==='emitter'&&!record.coverage?.some((row:any)=>row.name==='emit_library'))
  throw Error('Missing typed library emission closure');
 if(mode!=='template'){
  const checked=readFileSync(output,'utf8').match(/^import (\S+) as Checked$/m)?.[1];
  if(!checked||realpathSync(resolve(dirname(output),checked))!==realpathSync('bend2/selfhost/checked_frontend.bend'))
   throw Error('Typed '+mode+' must share the canonical owning Checked boundary');
 }
}
const declaration=source.match(/^(?:type|def) /m);
if(declaration?.index===undefined)throw Error('Missing complete parser declarations');
const originalHeader=source.slice(0,declaration.index),declarations=source.slice(declaration.index);
const importChanges:{before:string;after:string}[]=[];
const header=originalHeader.replace(/^import (\S+)( as [A-Za-z_][A-Za-z0-9_]*)?$/gm,(line,path:string,alias:string|undefined)=>{
 if(path==='Base')return line;
 if(!path.endsWith('.bend')||!alias)throw Error('Unexpected parser import: '+line);
 let next=relative(dirname(resolve(output)),resolve(dirname(parserSource),path)).replaceAll('\\','/');
 if(!next.startsWith('.'))next='./'+next;
 const after='import '+next+alias;importChanges.push({before:line,after});return after;
});
// The parser and the complete native library share lexical import namespaces:
// constructor tags must remain identical across their authentic AST transport.
if(header!==originalHeader)throw Error('Compiler root must preserve the accepted parser import header');
const imports='import ../bend2/selfhost/loaded_module.bend as Loader\nimport ../bend2/selfhost/checked_frontend.bend as Checked\nimport ./template_steps_v1.bend as Template\nimport ./checker_core_steps_v1.bend as CheckerCore\nimport ./js_emit_steps_v1.bend as JSEmit\n\n';
const wrappers=`
# Bend owns parsing, expansion, checking and emission; Node drives typed steps.
def parsed_module(namespace: String, module: Ast.Module) -> Loader.LoadedModule:
  Loader.LoadedModule{namespace, module}

def expand_modules_start(modules: List<&2, Loader.LoadedModule>) -> Template.TemplateRun<Template.ExpandResult>:
  Template.template_start(modules)

def template_step(-R: Type, run: Template.TemplateRun<R>) -> Template.TemplateRun<R>:
  Template.template_step(R, run)

def check_expanded_start(modules: List<&2, Loader.LoadedModule>) -> CheckerCore.CheckerRun<Checked.CheckResult>:
  CheckerCore.checker_start(modules)

def inspect_checked_start(program: Checked.CheckedProgram) -> CheckerCore.CheckerRun<Checked.Inspection>:
  CheckerCore.checker_inspect_start(program)

def checker_step(-R: Type, run: CheckerCore.CheckerRun<R>) -> CheckerCore.CheckerRun<R>:
  CheckerCore.checker_step(R, run)

def emit_modules_start(program: Checked.CheckedProgram) -> JSEmit.EmitterRun<JSEmit.EmitResult>:
  JSEmit.emitter_start(program)

def emit_library_start(program: Checked.CheckedProgram, exports: List<&2, String>) -> JSEmit.EmitterRun<JSEmit.EmitResult>:
  JSEmit.emitter_library_start(program, exports)

def emitter_step(-R: Type, run: JSEmit.EmitterRun<R>) -> JSEmit.EmitterRun<R>:
  JSEmit.emitter_step(R, run)
`;
const existing=new Set([...declarations.matchAll(/^def ([^ (]+)\(/gm)].map(x=>x[1]));
for(const match of wrappers.matchAll(/^def ([^ (]+)\(/gm))if(existing.has(match[1]))throw Error('Compiler wrapper shadows parser definition: '+match[1]);
const prefix=header+imports,root=prefix+declarations+wrappers;
const embedding={start:prefix.length,chars:declarations.length,sha256:sha(declarations)};
if(root.slice(embedding.start,embedding.start+embedding.chars)!==declarations)throw Error('Parser declaration composition drift');
for(const [path,digest]of Object.entries({...authenticated.authenticatedInputs,...typedStepInputs}))
 if(sha(readFileSync(path))!==digest)throw Error('Root source input changed during assembly: '+path);
writeFileSync(output,root);
writeFileSync(manifest,JSON.stringify({schemaVersion:1,algorithm:'Exact accepted parser declarations in root namespace; import-path-only relocation plus typed compiler wrappers',parserBuild:authenticated.parserBuild,parserBuildSha256:sha(readFileSync(authenticated.parserBuild)),parserProvenancePath:authenticated.provenancePath,parserProvenanceSha256:authenticated.accepted.provenanceSha256,officialKernelRelease:release,officialKernelSha256:authenticated.officialKernelSha256,authenticatedParserInputs:authenticated.authenticatedInputs,authenticatedTypedStepInputs:typedStepInputs,parserSource:resolve(parserSource),parserSourceSha256:sha(source),parserDeclarationStart:declaration.index,parserDeclarationSha256:sha(declarations),output:resolve(output),outputSha256:sha(root),embedding,importChanges,wrapperSha256:sha(wrappers),generator:resolve(import.meta.path),generatorSha256:sha(readFileSync(import.meta.path,'utf8')),parserBodiesChanged:0,parserDatatypesChanged:0,parserRequestKontChanged:false},null,2)+'\n');
console.log(JSON.stringify({output,manifest,chars:root.length,parserDeclarationsUnchanged:true}));
}
if(import.meta.main){
 const args=process.argv.slice(2);
 if(args.length!==1||!args[0]!.startsWith('--parser-build=')||!args[0]!.slice('--parser-build='.length))
  throw Error('Usage: bun evals/selfhost_driver_source.ts --parser-build=<fresh canonical native-build.result.json>');
 assembleSelfhostDriver(args[0]!.slice('--parser-build='.length));
}
