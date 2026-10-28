import {createHash} from 'node:crypto';
import {existsSync,mkdirSync,readFileSync,writeFileSync} from 'node:fs';
import {dirname,join,resolve} from 'node:path';
import {spawnSync} from 'node:child_process';
import {runHeavyGate} from './heavy_gate.ts';

// One focused consumer-ABI smoke, not a bootstrap/fixedpoint claim: the
// accepted compiled parser feeds the regenerated Template/Checker/JSEmit steps,
// the host supplies one real foreign effect's bytes through the passive
// BIR.SourceFile bag, and the unchanged emitted JS is executed for its output.
const fixture=resolve('evals/fir_foreign_effect.js');
const exportsList=['main','fir_mark'];
const source=`import Base

def fir_mark(text: String) -> IO(Unit):
  import "./fir_foreign_effect.js"

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- fir_mark("smoke")
    return Unit{}
`;
const sha=(bytes:string|Uint8Array)=>createHash('sha256').update(bytes).digest('hex');
const options=new Map(process.argv.slice(2).map(arg=>{
 const at=arg.indexOf('=');
 if(at<0)throw Error('Expected --option=value');
 return [arg.slice(0,at),arg.slice(at+1)];
}));
for(const name of ['--component','--component-build','--parser','--parser-build','--report'])if(!options.has(name))throw Error('Required '+name);
const component=resolve(options.get('--component')!),componentBuild=resolve(options.get('--component-build')!);
const parser=resolve(options.get('--parser')!),parserBuild=resolve(options.get('--parser-build')!);
const report=resolve(options.get('--report')!),sidecars=report+'.cases';
const criterion='One real foreign effect\'s bytes reach the JS renderer only through the host-built List<&2, BIR.SourceFile> bag, for both the library and module emitter entries, and the unchanged emitted JS prints that effect\'s output.';
function json(path:string):Record<string,any>{
 const value=JSON.parse(readFileSync(path,'utf8'));
 if(!value||typeof value!=='object'||Array.isArray(value))throw Error('Expected report object: '+path);
 return value as Record<string,any>;
}
function build(path:string,artifact:string,kind:string){
 const value=json(path);
 if(value.status!=='JS_GENERATED_NOT_YET_EXECUTED'||value.checksExcluded!==0||value.outputPatches!==0
  ||typeof value.artifactPath!=='string'||resolve(value.artifactPath)!==artifact||value.artifactSha256!==sha(readFileSync(artifact))
  ||typeof value.sourcePath!=='string'||value.sourceSha256!==sha(readFileSync(value.sourcePath))
  ||!Number.isSafeInteger(value.checkedDefinitions)||value.checkedDefinitions<=0)
  throw Error('Incomplete or mismatched '+kind+' build provenance: '+path);
 return value;
}
if(existsSync(report)||existsSync(sidecars))throw Error('Use a fresh smoke report path; evidence is never overwritten');
mkdirSync(dirname(report),{recursive:true});
const state:Record<string,any>={status:'IN_PROGRESS',passed:false,smokeOnly:true,criterion,
 boundary:{hostBag:'one shared checker_core_step_runtime.mjs sourceFiles factory',declaredPaths:'Bend DefImports alternatives',linkMetadata:'BIR only',hostParsing:false,hostChecking:false,outputPatches:0,checksExcluded:0,bootstrapFixedpointClaim:false},
 inputs:{},rows:[]};
const flush=()=>writeFileSync(report,JSON.stringify(state,null,2)+'\n');
flush();
try{
 const componentReport=build(componentBuild,component,'component');
 const parserReport=build(parserBuild,parser,'parser');
 const componentExports=['parsed_module','expand_modules_start','template_step','check_expanded_start','checker_step','emit_modules_start','emit_library_start','emitter_step'];
 if(!Array.isArray(componentReport.exports)||!componentExports.every(name=>componentReport.exports.includes(name)))throw Error('Smoke component must export the current typed step ABI');
 for(const path of [component,componentBuild,parser,parserBuild,fixture,resolve('evals/fir_foreign_smoke_worker.mjs'),resolve('evals/checker_core_step_runtime.mjs'),import.meta.path])
  state.inputs[path]=sha(readFileSync(path));
 mkdirSync(sidecars,{recursive:true});
 const file=join(sidecars,'fir_foreign_smoke.bend'),effect=join(sidecars,'fir_foreign_effect.js');
 writeFileSync(file,source);
 writeFileSync(effect,readFileSync(fixture));
 state.inputs[file]=sha(readFileSync(file));
 state.inputs[effect]=sha(readFileSync(effect));
 if(state.inputs[effect]!==sha(readFileSync(fixture)))throw Error('Copied fixture effect bytes differ from the committed source');
 const request=join(sidecars,'request.json');
 writeFileSync(request,JSON.stringify({file,effect,effectPath:effect,effectSha256:sha(readFileSync(effect)),marker:'fir-foreign:',loadMarker:'fir-foreign-loaded',source,exports:exportsList,expected:'fir-foreign:smoke',base:resolve('bend2/base.bend'),component,parser,sidecars}));
 state.request=request;
 flush();
 const guardian=await runHeavyGate(['node',resolve('evals/fir_foreign_smoke_worker.mjs'),request],{label:'FIR foreign-source consumer ABI smoke',memoryMiB:8192,rssMiB:8192,pollMs:10});
 state.guardian=guardian;
 if(guardian.status!=='PASS')throw Error('Smoke guardian '+guardian.status+': '+guardian.reason);
 const result=json(join(sidecars,'result.json'));
 state.rows=result.rows;
 const rows=Array.isArray(result.rows)?result.rows:[];
 state.passed=result.passed===true&&rows.length===2&&rows.every((row:Record<string,unknown>)=>row.passed===true)
  &&rows[0].output==='fir-foreign-loaded'&&rows[1].output==='fir-foreign-loaded\nfir-foreign:smoke';
 state.status=state.passed?'FOREIGN_CONSUMER_ABI_SMOKE_PASS':'FAIL';
}catch(error){
 state.failure={error:String(error)};
 state.status='FAIL';
 state.passed=false;
}
flush();
console.log(JSON.stringify({status:state.status,passed:state.passed,report}));
if(!state.passed)process.exitCode=2;
