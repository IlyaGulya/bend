import {createHash} from 'node:crypto';
import {readFileSync,writeFileSync,realpathSync,mkdirSync} from 'node:fs';
import {resolve,dirname,join} from 'node:path';

const options=new Map(process.argv.slice(2).map(arg=>{const at=arg.indexOf('=');if(at<0)throw Error('Expected --option=value');return [arg.slice(0,at),arg.slice(at+1)];}));
function required(name:string){const value=options.get(name);if(!value)throw Error('Required '+name);return resolve(value);}
const buildPath=required('--build-result'),corpusPath=required('--corpus-report'),reportPath=required('--report');
const sha=(bytes:Uint8Array)=>createHash('sha256').update(bytes).digest('hex');
const json=(path:string)=>JSON.parse(readFileSync(path,'utf8'));
const build=json(buildPath),corpus=json(corpusPath),artifact=resolve(build.artifactPath),artifactSha256=sha(readFileSync(artifact));
if(artifactSha256!==build.artifactSha256||artifactSha256!==corpus.artifactSha256)throw Error('Artifact provenance mismatch');
if(build.checksExcluded!==0||!corpus.fullCorpus||!corpus.finished||!corpus.complete||!corpus.passed||corpus.rows.length!==10||corpus.counts.fullFileParseSuccess!==10||corpus.counts.normalizedSemanticParity!==10)throw Error('Full native validation and complete ten-module parity are prerequisites');
const candidate=realpathSync(build.sourceCandidate);
if(sha(readFileSync(candidate))!==build.candidateSha256)throw Error('Stage1 generated candidate provenance mismatch');
const roots=[realpathSync(options.get('--driver')??'checkpoints/checker_core_driver.bend'),candidate];
const pending=[...roots],seen=new Set<string>(),modules:any[]=[],failures:any[]=[];
const sidecars=reportPath+'.modules';mkdirSync(sidecars,{recursive:true});
function accepted(row:any){return row.sourceScope==='full-file'&&row.complete&&row.parseCompleted&&row.fullFileParseSuccess&&row.compiledAccepted&&row.stage0Accepted&&row.acceptanceParity&&row.semanticParity&&row.normalizedSemanticParity&&row.status==='parity';}
function importPath(file:string,path:string){return realpathSync(path==='Base'?resolve('bend2/base.bend'):resolve(dirname(file),path.endsWith('.bend')?path:path+'.bend'));}
function save(complete=false){
 const totals=modules.reduce((sum,row)=>({declarations:sum.declarations+row.declarationCount,templateDefinitions:sum.templateDefinitions+row.templateDefinitionCount,TemplateBinder:sum.TemplateBinder+row.constructorCensus.TemplateBinder,TermTemplate:sum.TermTemplate+row.constructorCensus.TermTemplate}),{declarations:0,templateDefinitions:0,TemplateBinder:0,TermTemplate:0});
 writeFileSync(reportPath,JSON.stringify({status:complete?(totals.TemplateBinder||totals.TermTemplate?'T1':'T0'):failures.length?'BLOCKED':'IN_PROGRESS',complete,moduleClosureDiscovered:complete,allSourceParity:complete,roots,artifact,artifactSha256,buildResult:buildPath,corpusReport:corpusPath,limits:corpus.limits,closureDiscovery:'Fixedpoint of imports from complete compiled-parser ASTs; realpath deduplication; no prefix fallback.',specialConstructorPolicy:'Counts actual TemplateBinder and TermTemplate AST constructors, not PatternCtr names or implementation constructor strings. Template definitions contain a TemplateBinder in DefTop binders.',modules,failures,totals:complete?totals:null,parsedLowerBound:totals},null,2)+'\n');
}
save();
try{
 while(pending.length){
  const file=realpathSync(pending.shift()!);if(seen.has(file))continue;seen.add(file);
  const sourceSha256=sha(readFileSync(file));
  let row=corpus.rows.find((row:any)=>realpathSync(row.file)===file&&row.sourceSha256===sourceSha256&&accepted(row));
  let parityReport=corpusPath;
  if(!row){
   parityReport=join(sidecars,String(modules.length+1)+'.json');
   const child=Bun.spawn([process.execPath,'--smol',resolve('evals/bootstrap_parser_isolated_corpus.ts'),'--artifact='+artifact,'--file='+file,'--timeout-ms=900000','--report='+parityReport],{stdout:'inherit',stderr:'inherit'});
   const exitCode=await child.exited,proof=json(parityReport);
   row=proof.rows[0];
   if(exitCode!==0||proof.artifactSha256!==artifactSha256||proof.rows.length!==1||!accepted(row)||row.sourceSha256!==sourceSha256)throw Error('Complete source parity failed: '+file+'; report '+parityReport);
  }
  if(!Array.isArray(row.imports)||!Number.isSafeInteger(row.declarationCount)||!Number.isSafeInteger(row.templateDefinitionCount)||!Number.isSafeInteger(row.constructorCensus?.TemplateBinder)||!Number.isSafeInteger(row.constructorCensus?.TermTemplate))throw Error('Missing complete AST metadata: '+file);
  const imports=row.imports.map((entry:any)=>({...entry,resolved:importPath(file,entry.path)}));
  modules.push({file,sourceSha256,fullFileParseSuccess:true,normalizedSemanticParity:true,stage0ASTHash:row.stage0ASTHash,compiledASTHash:row.compiledASTHash,declarationCount:row.declarationCount,templateDefinitionCount:row.templateDefinitionCount,constructorCensus:row.constructorCensus,imports,parityReport,guardian:row.guardian});
  pending.push(...imports.map((entry:any)=>entry.resolved));save();
  console.log(JSON.stringify({stage:'closure-module',file,declarations:row.declarationCount,remaining:pending.length}));
 }
 save(true);console.log(JSON.stringify({stage:'closure-fixedpoint',modules:modules.length,report:reportPath}));
}catch(error){failures.push({error:String(error),next:pending[0]??null});save();console.error(error);process.exitCode=2;}
