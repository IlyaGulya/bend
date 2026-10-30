#!/usr/bin/env node
import assert from 'node:assert/strict';
import {readFileSync,writeFileSync,existsSync,mkdirSync,realpathSync,openSync,closeSync} from 'node:fs';
import {spawnSync} from 'node:child_process';
import {resolve,dirname,relative,delimiter} from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
import {ABI,LIMITS,authenticate,guardian,hash,json,save,verify,expectations} from './common.mjs';
const here=dirname(fileURLToPath(import.meta.url));
const usage='node --experimental-strip-types cli.mjs prepare|run|qualify --repo=PATH --experiment=e06|e10 --run-id=UNIQUE --out=FRESH_OR_PREPARED_DIR --source-commit=COMMIT [--node=PATH --bun=PATH --clang=PATH] (qualify also needs --preflight=DIR --bindings=PATH --frozen-repository=PATH --control-native=PATH --control-image=PATH)';
const [action,...args]=process.argv.slice(2);if(action==='--help'){console.log(usage);process.exit(0);}
assert.ok(['prepare','run','qualify'].includes(action),usage);
const o={};for(const a of args){const m=/^--([a-z-]+)=(.+)$/.exec(a);assert.ok(m,'expected --option=value');assert.ok(!Object.hasOwn(o,m[1]),'duplicate option');o[m[1]]=m[2];}
for(const k of Object.keys(o))assert.ok(['repo','experiment','run-id','out','source-commit','node','bun','clang','preflight','bindings','frozen-repository','control-native','control-image'].includes(k),'unknown '+k);
for(const k of ['repo','experiment','run-id','out','source-commit'])assert.ok(o[k],'missing '+k);
assert.ok(['e06','e10'].includes(o.experiment));assert.match(o['run-id'],/^[a-zA-Z0-9_-]+$/);
const repo=realpathSync(o.repo),out=resolve(o.out),runId=o['run-id'];process.chdir(repo);
function executable(name){const r=name.includes('/')?name:spawnSync('which',[name],{encoding:'utf8'}).stdout.trim();return realpathSync(r);}
const node=executable(o.node??process.execPath),bun=executable(o.bun??'bun'),clang=executable(o.clang??'/usr/bin/clang');
// Existing self-guarded builders resolve literal `node`; pin that executable too.
process.env.PATH=dirname(node)+delimiter+process.env.PATH;assert.equal(executable('node'),node);
Object.assign(process.env,{HEAVY_GATE_MEMORY_MIB:'8192',HEAVY_GATE_RSS_MIB:'8192',HEAVY_GATE_POLL_MS:'10',HEAVY_GATE_TIMEOUT_MS:'600000'});
const {runHeavyGate}=await import(pathToFileURL(resolve(repo,'evals/heavy_gate.ts')).href);
const git=(...a)=>{const r=spawnSync('git',a,{cwd:repo,encoding:'utf8',maxBuffer:16*1024*1024});assert.equal(r.status,0,r.stderr);return r.stdout;};
const commit=git('rev-parse',o['source-commit']+'^{commit}').trim();
const authored=['bend2/selfhost/lower_catalog.bend','bend2/selfhost/backend_lower.bend','bend2/selfhost/js_backend.bend','evals/emitter_step_lower.ts'];
for(const p of authored)assert.equal(readFileSync(resolve(repo,p),'utf8'),git('show',commit+':'+p),'source not checkpointed '+p);
const contextCarried=readFileSync(resolve(repo,authored[0]),'utf8').includes('normalizer: DescriptorNf.NfContext');
const markerCarried=/def program_source\([^\n]*natives: Map/.test(readFileSync(resolve(repo,authored[2]),'utf8'));
assert.equal(contextCarried,o.experiment==='e06','isolated E06 source mismatch');assert.equal(markerCarried,o.experiment==='e10','isolated E10 source mismatch');
if(o.experiment==='e06'){
 const scratch=resolve(repo,'bend2/selfhost/.global57j-js_emit.bend');
 if(existsSync(scratch))assert.ok(readFileSync(scratch,'utf8').includes('Catalog.Catalog{work, registry, constructors, families, type_functions, next_code, ending, _}'),'migrate live optional scratch Catalog caller before preflight');
}
assert.ok(!readFileSync(resolve(repo,'evals/emitter_step_lower.ts'),'utf8').includes("'bend2/selfhost/backend_continuation.bend'"),'restore R12 before isolated reuse candidates');
const rows=[];
async function run(label,command,guarded=true){
 const log=resolve(out,'logs',String(rows.length).padStart(3,'0')+'-'+label),row={label,command,guarded,stdout:log+'.stdout',stderr:log+'.stderr'};rows.push(row);
 if(guarded){
  // A tiny capture subprocess only redirects descriptors; the native guardian owns its entire tree.
  const capture=resolve(here,'capture.mjs');
  row.guardian=await runHeavyGate([node,capture,row.stdout,row.stderr,...command],{...LIMITS,label:'reuse preflight '+label});guardian(row.guardian);
 }else{
  const stdout=openSync(row.stdout,'wx'),stderr=openSync(row.stderr,'wx');let r;
  try{r=spawnSync(command[0],command.slice(1),{cwd:repo,stdio:['ignore',stdout,stderr]});}finally{closeSync(stdout);closeSync(stderr);}
  row.exitCode=r.status;row.signal=r.signal;assert.equal(r.status,0,label+': '+row.stderr);
 }
 row.stdoutSha256=hash(row.stdout);row.stderrSha256=hash(row.stderr);save(resolve(out,'commands.json'),rows);return row;
}
if(action==='qualify'){
 const pre=realpathSync(o.preflight),receipt=json(resolve(pre,'receipt.json')),prepared=json(resolve(pre,'prepared.json'));
 assert.equal(receipt.status,'PREFLIGHT_PASS');assert.equal(receipt.experiment,o.experiment);assert.equal(receipt.sourceCommit,commit);verify(prepared.pins);assert.notEqual(runId,prepared.runId);assert.notEqual(out,pre);assert.ok(!existsSync(out));
 for(const k of ['bindings','frozen-repository','control-native','control-image'])assert.ok(o[k],'missing '+k);
 const command=[bun,'--smol',resolve(repo,'evals/g24_qualification.mjs'),'--run-id='+runId,'--out='+out,'--phase=all','--fail-fast-performance=true','--node='+node,'--bun='+bun,'--clang='+clang,...['bindings','frozen-repository','control-native','control-image'].map(k=>'--'+k+'='+resolve(o[k]))];
 console.log(JSON.stringify({scope:'separate complete qualification; preflight is not acceptance',command}));const r=spawnSync(command[0],command.slice(1),{cwd:repo,stdio:'inherit'});process.exit(r.status??1);
}
if(action==='prepare'){
 assert.ok(!existsSync(out),'fresh preflight out required');mkdirSync(resolve(out,'logs'),{recursive:true});
 const cp=resolve(repo,'checkpoints'),stem=resolve(cp,'bootstrap-parser-rebuild-'+runId),parserSource=resolve(cp,'.bootstrap_parser_rebuild_'+runId+'_source.bend'),parserCandidate=resolve(cp,'.bootstrap_parser_rebuild_'+runId+'_generated_fuel.bend');
 const root=resolve(cp,'.bootstrap_compiler_root_'+runId+'.bend'),rootManifest=resolve(cp,'selfhost-root-'+runId+'.json'),build=resolve(out,'root-build'),image=resolve(out,'root.js');
 for(const p of [root,rootManifest,parserSource,parserCandidate,stem+'.request.json',stem+'.native-build.result.json'])assert.ok(!existsSync(p),'run-id already used: '+p);
 const sourcePublic=resolve(out,'parser-public-source.json'),sourceGate=resolve(out,'parser-source-gate.json'),nativePublic=resolve(out,'parser-public-native.json'),candidateGate=resolve(out,'parser-candidate-gate.json');
 const b=(script,...a)=>[bun,'--smol',resolve(repo,'evals',script),...a];
 try{
  for(const script of ['checker_core_owned_source.ts','template_step_lower.ts','checker_core_step_lower.ts','emitter_step_lower.ts'])await run(script,b(script));
  // Actual repository prepare/accept interfaces, in the same order as G24. These acquire their own gates.
  await run('parser-source',b('bootstrap_parser_rebuild.ts','--prepare-source','--run-id',runId),false);
  await run('parser-public-source',b('bootstrap_parser_public_gate.ts','--parser='+parserSource,'--entry=parse_module_tokens','--report='+sourcePublic),false);
  await run('parser-source-gate',b('bootstrap_parser_fast.ts','--parser='+parserSource,'--entry=parse_module_tokens','--public-report='+sourcePublic,'--report='+sourceGate),false);
  await run('parser-prepare',b('bootstrap_parser_rebuild.ts','--prepare','--run-id',runId,'--source-gate',sourceGate),false);
  await run('parser-build',b('bootstrap_parser_rebuild.ts','--build-native','--run-id',runId),false);
  await run('parser-public-native',b('bootstrap_parser_public_gate.ts','--parser='+parserCandidate,'--entry=parse_with_fuel','--report='+nativePublic),false);
  await run('parser-native-gate',b('bootstrap_parser_fast.ts','--parser='+parserCandidate,'--entry=parse_with_fuel','--component='+stem+'.js','--component-build='+stem+'.native-build.result.json','--public-report='+nativePublic,'--report='+candidateGate),false);
  await run('parser-accept',b('bootstrap_parser_rebuild.ts','--build','--run-id',runId,'--candidate-gate',candidateGate),false);
  await run('compose',b('selfhost_driver_source.ts','--parser-build='+stem+'.native-build.result.json','--root='+root,'--manifest='+rootManifest));
  // Do not put another exclusive guardian around this self-guarded builder.
  await run('js-build',b('checker_core_component_build.ts','--file='+root,'--exports='+ABI.join(','),'--artifact='+image,'--report='+build),false);
  const authenticated=authenticate(repo,build+'.result.json');
  const pins={...authenticated.pins};
  for(const source of authenticated.manifest.canonicalComposition.sources)
   assert.equal(readFileSync(resolve(repo,source.canonical),'utf8'),git('show',commit+':'+source.canonical),'provider not checkpointed '+source.canonical);
  for(const p of [rootManifest,...['cli.mjs','common.mjs','probes.mjs','compile-worker.mjs','capture.mjs','normalize-smoke.ts'].map(p=>resolve(here,p)),resolve(repo,'evals/checker_core_step_runtime.mjs'),resolve(repo,'bend2/selfhost/c_runtime.c')])pins[realpathSync(p)]=hash(p);
  save(resolve(out,'prepared.json'),{status:'PREPARED_NOT_EXECUTED',experiment:o.experiment,sourceCommit:commit,runId,repo,out,root,rootManifest,build:build+'.result.json',image,pins,limits:LIMITS,abi:ABI,node:{path:node,sha256:hash(node)},bun:{path:bun,sha256:hash(bun)},clang:{path:clang,sha256:hash(clang)},canonicalBuildWorker:{stackMiB:256,oldMiB:3072,manualGC:false},imageWorker:{stackMiB:256,oldMiB:6144,youngMiB:128},commands:rows});
 }catch(error){save(resolve(out,'prepare-failure.json'),{status:'FAIL',error:String(error?.stack??error),commands:rows});throw error;}
}else{
 const prepared=json(resolve(out,'prepared.json'));assert.equal(prepared.experiment,o.experiment);assert.equal(prepared.sourceCommit,commit);assert.equal(prepared.runId,runId);assert.equal(prepared.repo,repo);verify(prepared.pins);
 for(const [name,path]of Object.entries({node,bun,clang})){assert.equal(prepared[name].path,path);assert.equal(prepared[name].sha256,hash(path));}
 const suite=resolve(out,'consumers');assert.ok(!existsSync(suite),'consumer namespace already used');mkdirSync(suite);
 const receipt={status:'RUNNING',experiment:o.experiment,sourceCommit:commit,runId,compilerAccepted:false,performanceAccepted:false,fixedpoint:false,limits:LIMITS,rows:[],commands:rows};const publish=()=>save(resolve(out,'receipt.json'),receipt);publish();
 try{
  const cases=['tests/run/descriptor_show.bend','tests/check/data_alias_whnf_000.bend','tests/compile/alias_def.bend','tests/reg/native_erased_layout.bend','tests/io/foreign_types.bend'].map(source=>({name:source.replaceAll('/','-').replace('.bend',''),source:resolve(repo,source)}));
  await run('normalize-descriptor-smoke',[bun,'--smol',resolve(here,'normalize-smoke.ts'),repo,suite]);
  const smoke=resolve(suite,'descriptor-semantics.bend');cases.push({name:'descriptor-semantics',source:smoke});
  const noMain=resolve(suite,'no-main.bend');writeFileSync(noMain,'import Base\n\ndef twice(x: U32) -> U32:\n  U32.add(x, x)\n\n#|bend: executable mode requires a root main definition\n',{flag:'wx'});cases.push({name:'no-main',source:noMain,error:true});
  const library=resolve(repo,'evals/c_step_library_fixture.bend');cases.push({name:'native-export',source:library,exports:['U32.mul'],expected:'6\n',caller:resolve(repo,'evals/c_backend_native_export_caller.c')});
  cases.push({name:'six-exports',source:library,exports:['add','symbol_add','partial','zero','factory','mk'],expected:'export ok\n',caller:resolve(repo,'evals/c_backend_library_caller.c')});
  for(const fixture of cases)for(const target of ['c','js']){
   const expected=fixture.expected??expectations(readFileSync(fixture.source,'utf8')),row={name:fixture.name,source:fixture.source,sourceSha256:hash(fixture.source),target,expected,error:!!fixture.error,exports:fixture.exports,runs:[]};receipt.rows.push(row);publish();
   const frozenInputs={...prepared.pins,[realpathSync(fixture.source)]:row.sourceSha256};
   if(fixture.caller)frozenInputs[realpathSync(fixture.caller)]=hash(fixture.caller);
   for(const instrument of [false,true]){
    const stem=resolve(suite,fixture.name+'-'+target+(instrument?'-probe':'-clean')),output=stem+(target==='c'?'.c':'.js'),report=stem+'.json',request=stem+'.request.json';
    save(request,{repo,experiment:o.experiment,build:prepared.build,source:fixture.source,target,output,report,exports:fixture.exports,expectedError:fixture.error?expected:undefined,instrument,pins:frozenInputs});
    const command=[node,'--experimental-strip-types','--max-old-space-size=6144','--max-semi-space-size=128',resolve(here,'compile-worker.mjs'),request];
    const stage=await run('emit-'+fixture.name+'-'+target+(instrument?'-probe':'-clean'),command);const result=json(report);assert.equal(result.status,'PASS',result.error);row.runs.push({report,reportSha256:hash(report),guardian:stage.guardian,output:result.output,probe:result.probe,expectedRejection:result.expectedRejection,inputs:result.inputs});
    if(instrument){assert.deepEqual(row.runs[0].inputs,result.inputs,'source bag differs between clean/probe');assert.equal(result.output?.sha256,row.runs[0].output?.sha256,'observer changed output');assert.deepEqual(result.expectedRejection,row.runs[0].expectedRejection);}
    publish();
   }
   if(!fixture.error){
    const output=row.runs[0].output.path;let command;
    if(target==='c'){
     const exe=resolve(suite,fixture.name+'-c.exe');row.build=await run('clang-'+fixture.name,[clang,'-std=c11','-O1','-pthread',output,...(fixture.caller?[fixture.caller]:[]),'-lm','-o',exe]);command=[exe];
    }else if(fixture.exports){
     const caller=resolve(suite,fixture.name+'-js-caller.mjs');const body=fixture.name==='native-export'?'assert.equal(lib["U32.mul"](2,3),6);console.log(6);':'assert.deepEqual(Object.keys(lib),["add","symbol_add","partial","zero","factory","mk"]);assert.equal(lib.add(2,3),5);assert.equal(lib.symbol_add(2,3),5);assert.equal(lib.partial(5,7),12);assert.equal(lib.zero(),9);assert.equal(lib.mk(),9);assert.equal(lib.factory(7),12);assert.equal(lib.factory()(8),13);console.log("export ok");';
     writeFileSync(caller,'import assert from "node:assert/strict";\nimport lib from '+JSON.stringify(pathToFileURL(output).href)+';\n'+body+'\n',{flag:'wx'});row.jsCaller={path:caller,sha256:hash(caller)};command=[node,caller];
    }else command=[node,output];
    row.consumer=await run('consumer-'+fixture.name+'-'+target,command);assert.equal(readFileSync(row.consumer.stdout,'utf8'),expected,'#| output mismatch');
   }
   verify(frozenInputs);
   for(const emitted of row.runs){verify(emitted.inputs);if(emitted.output)assert.equal(hash(emitted.output.path),emitted.output.sha256,'emitted source changed after execution');}
   row.status='PASS';publish();
  }
  assert.equal(receipt.rows.length,cases.length*2,'missing C/JS source row');
  if(o.experiment==='e06')for(const target of ['c','js'])
   assert.ok(receipt.rows.some(r=>r.target===target&&(r.runs[1].probe?.counts.describe??0)>0),'no actual lowering descriptor consumer on '+target);
  for(const r of receipt.rows)if(!r.error&&(o.experiment==='e06'||r.target==='js'))
   assert.equal(r.runs[1].probe?.positivePassed,true,'missing exact reuse evidence '+r.name);
  verify(prepared.pins);receipt.status='PREFLIGHT_PASS';receipt.scope='Actual full compiler RootJS algorithms, C/JS ordinary consumers and scalar compiled-path identity probes; not native qualification or acceptance';publish();
 }catch(error){receipt.status='FAIL';receipt.error=String(error?.stack??error);publish();throw error;}
}
