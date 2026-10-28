#!/usr/bin/env node
/** G24 changed-path source smoke (bend-nxf.30).
 *
 * A small, durable driver for an explicit list of repository Bend sources. It
 * emits each source through the canonical bend2/bend.ts + bend2/comp.ts engine
 * in the accepted worker transport (256 MiB stack, 3072 MiB old generation),
 * builds C at clang -O1 when the C target is selected, then runs the C or JS
 * consumer and requires its stdout to equal the source's exact `#|` lines.
 *
 * Every heavy stage (emission, clang, consumer) runs alone under the existing
 * exclusive heavy gate: 8192 MiB footprint, 8192 MiB RSS, 10 ms sampling,
 * 600000 ms deadline. Child processes are never run concurrently.
 *
 * This is a changed-path smoke, not compiler acceptance: it does not prove
 * selfhost admission, native stage1/stage2 byte fixedpoint, throughput, or any
 * existing gate. Nothing here may be reported as such.
 *
 * Usage:
 *   node evals/g24_source_smoke.mjs --fixtures tests/run/a.bend,tests/run/b.bend
 *   node evals/g24_source_smoke.mjs tests/run/a.bend tests/compile/b.bend --targets js
 * Options:
 *   --fixtures <list>  comma/space separated repository .bend sources (repeatable)
 *   --targets <list>   c,js (default) or js or c
 *   --receipt <path>   receipt path (default: <temporary directory>/receipt.json)
 *   --node <path>      node executable (default: the running node)
 *   --bun <path>       bun executable used to launch evals/heavy_gate.ts (default: bun)
 *   --clang <path>     C compiler (default: /usr/bin/clang)
 *   --help             print this usage
 *
 * Invoke this driver directly. Do not wrap it in evals/heavy_gate.ts: it guards
 * each stage itself and the gate lease is exclusive.
 *
 * A fixture may import the generated typed checker steps under checkpoints/
 * (for example tests/selfhost/*.bend importing checker_core_steps_v1.bend). The
 * generated sources are not tracked; regenerate them first with
 * `bun evals/checker_core_step_lower.ts`. Their hashes are recorded when present
 * so the receipt shows what the fixture was emitted against.
 */
import {createHash} from 'node:crypto';
import {createReadStream, existsSync, mkdtempSync, readFileSync, realpathSync, statSync, writeFileSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {basename, join, relative, resolve, sep} from 'node:path';
import {spawn, spawnSync} from 'node:child_process';
import {fileURLToPath} from 'node:url';

const REPO_ROOT=realpathSync(resolve(fileURLToPath(new URL('..',import.meta.url))));
const WORKER=fileURLToPath(new URL('./g24_source_smoke_worker.mjs',import.meta.url));
const GATE=join(REPO_ROOT,'evals/heavy_gate.ts');
const LIMITS=Object.freeze({memoryMiB:8192,rssMiB:8192,pollMs:10,timeoutMs:600000});
const CAPTURE_BYTES=8*1024*1024;
const SAFETY_TIMEOUT_MS=LIMITS.timeoutMs+60000;
const TARGETS=new Set(['c','js']);
const USAGE=`usage: node evals/g24_source_smoke.mjs --fixtures <list> [options]
       node evals/g24_source_smoke.mjs <file.bend> [<file.bend> ...] [options]

options: --fixtures <comma/space list>  --targets c,js|js|c  --receipt <path>
         --node <path>  --bun <path>  --clang <path>  --help

Run from the repository root; fixture paths resolve against the current
directory and must be repository-contained. --targets js skips the C lane for
sources that are not C-target fixtures.

changed-path smoke only; it never proves compiler acceptance or fixedpoint.`;

function parseArguments(argv){
 const fixtures=[],config={targets:['c','js'],receipt:null,node:process.execPath,bun:process.env.BUN??'bun',clang:'/usr/bin/clang'};
 const option=(index,name)=>{const value=argv[index];if(value===undefined||value===''||value.startsWith('--'))throw Error(`missing value for ${name}`);return value;};
 for(let i=0;i<argv.length;i++){
  const argument=argv[i];
  if(argument==='--help'||argument==='-h')return {help:true};
  if(!argument.startsWith('--')){
   fixtures.push(argument);
   continue;
  }
  const equals=argument.indexOf('='),name=equals<0?argument:argument.slice(0,equals);
  const value=equals<0?option(++i,name):argument.slice(equals+1);
  if(value==='')throw Error(`missing value for ${name}`);
  switch(name){
   case '--fixtures':fixtures.push(...value.split(/[,\s]+/).filter(Boolean));break;
   case '--targets':config.targets=value.split(',').map(target=>target.trim()).filter(Boolean);break;
   case '--receipt':config.receipt=resolve(value);break;
   case '--node':config.node=value.includes('/')?resolve(value):value;break;
   case '--bun':config.bun=value.includes('/')?resolve(value):value;break;
   case '--clang':config.clang=value.includes('/')?resolve(value):value;break;
   default:throw Error(`unknown option: ${name}`);
  }
 }
 if(fixtures.length===0)throw Error('expected at least one --fixtures entry or positional .bend source');
 if(config.targets.length===0)throw Error('--targets needs at least one of c,js');
 for(const target of config.targets)if(!TARGETS.has(target))throw Error(`unknown target: ${target}`);
 config.targets=[...new Set(config.targets)];
 return {config,fixtures};
}

async function shaFile(path){
 const hash=createHash('sha256');
 await new Promise((resolveRead,rejectRead)=>{
  const stream=createReadStream(path);
  stream.on('data',chunk=>hash.update(chunk));
  stream.on('error',rejectRead);
  stream.on('end',resolveRead);
 });
 return hash.digest('hex');
}

async function hashPaths(paths){
 const out={};
 for(const path of paths){
  const absolute=resolve(REPO_ROOT,path);
  if(!existsSync(absolute))throw Error(`missing harness or compiler input: ${path}`);
  out[path]=await shaFile(absolute);
 }
 return out;
}

/** Generated typed checker steps are untracked; hash the ones that exist. */
async function hashGenerated(paths){
 const out={};
 for(const path of paths){
  const absolute=resolve(REPO_ROOT,path);
  if(existsSync(absolute))out[path]=await shaFile(absolute);
 }
 return out;
}

function resolveExecutable(command){
 const found=command.includes('/')?command:spawnSync('which',[command],{encoding:'utf8'}).stdout?.trim();
 if(!found)throw Error(`cannot resolve executable: ${command}`);
 return realpathSync(found);
}

function executableVersion(path,args,name){
 const probe=spawnSync(path,args,{encoding:'utf8',timeout:60000,maxBuffer:1024*1024});
 const text=((probe.stdout??'')+(probe.stderr??'')).split('\n').map(line=>line.trim()).find(Boolean);
 if(probe.status!==0||!text)throw Error(`cannot identify ${name} runtime: ${path}`);
 return text;
}

async function runtimeIdentity(command,args,name){
 const path=resolveExecutable(command);
 return {command,path,version:executableVersion(path,args,name),sha256:await shaFile(path)};
}

function repositorySource(given){
 const real=realpathSync(resolve(given));
 if(!(real===REPO_ROOT||real.startsWith(REPO_ROOT+sep)))throw Error(`source is not repository-contained: ${given}`);
 if(!statSync(real).isFile())throw Error(`source is not a regular file: ${given}`);
 if(!real.endsWith('.bend'))throw Error(`source is not a .bend file: ${given}`);
 return real;
}

function expectationsOf(text,source){
 // Canonical gates/test.ts extraction: every line startsWith "#|", the
 // expectation is the exact remainder after those two bytes, in file order.
 // Only the program's terminating newline is added for the byte comparison.
 const lines=text.split('\n').filter(line=>line.startsWith('#|'));
 if(lines.length===0)throw Error(`fixture has no #| expectation lines: ${relative(REPO_ROOT,source)}`);
 return lines.map(line=>line.slice(2)).join('\n')+'\n';
}

/** Run one command alone under the repository's exclusive sampled heavy gate. */
async function runGuarded(bunPath,label,command,expectedOutput){
 const limits=['--memory-mib',String(LIMITS.memoryMiB),'--rss-mib',String(LIMITS.rssMiB),'--poll-ms',String(LIMITS.pollMs),'--timeout-ms',String(LIMITS.timeoutMs)];
 const gateCommand=[bunPath,GATE,...limits,'--',...command];
 const record={label,command,gateCommand,limits:{...LIMITS},status:'FAIL'};
 const started=performance.now();
 let child;
 try{
  child=spawn(gateCommand[0],gateCommand.slice(1),{cwd:REPO_ROOT,stdio:['ignore','pipe','pipe'],env:{
   ...process.env,
   HEAVY_GATE_MEMORY_MIB:String(LIMITS.memoryMiB),
   HEAVY_GATE_RSS_MIB:String(LIMITS.rssMiB),
   HEAVY_GATE_POLL_MS:String(LIMITS.pollMs),
   HEAVY_GATE_TIMEOUT_MS:String(LIMITS.timeoutMs),
  }});
 }catch(error){
  record.error=`cannot start heavy gate: ${String(error)}`;
  record.elapsedMs=performance.now()-started;
  return record;
 }
 const outChunks=[],errChunks=[];
 let capturedOut=0,capturedErr=0,overflow=false,timedOut=false;
 const append=(chunk,side)=>{
  if(overflow)return;
  const captured=side==='out'?capturedOut:capturedErr;
  if(captured+chunk.length>CAPTURE_BYTES){
   overflow=true;
   child.kill('SIGTERM');
   return;
  }
  if(side==='out'){outChunks.push(chunk);capturedOut+=chunk.length;}
  else{errChunks.push(chunk);capturedErr+=chunk.length;}
 };
 child.stdout?.on('data',chunk=>append(chunk,'out'));
 child.stderr?.on('data',chunk=>append(chunk,'err'));
 const timer=setTimeout(()=>{timedOut=true;child.kill('SIGTERM');},SAFETY_TIMEOUT_MS);
 const settled=await new Promise(done=>{
  let finished=false;const finish=value=>{if(!finished){finished=true;clearTimeout(timer);done(value);}};
  child.once('error',error=>finish({error}));
  child.once('close',(code,signal)=>finish({code,signal}));
 });
 const output=Buffer.concat(outChunks,capturedOut);
 const stdout=output.toString('utf8'),stderr=Buffer.concat(errChunks,capturedErr).toString('utf8');
 if(expectedOutput!==undefined)record.outputMatches=output.equals(Buffer.from(expectedOutput,'utf8'));
 record.elapsedMs=performance.now()-started;
 record.stdout=stdout;
 record.stderr=stderr;
 if(settled.error){record.error=`heavy gate spawn failed: ${String(settled.error)}`;return record;}
 record.gateExitCode=settled.code;
 record.gateSignal=settled.signal;
 if(timedOut){record.error=`stage exceeded driver safety deadline ${SAFETY_TIMEOUT_MS} ms`;return record;}
 if(overflow){record.error=`captured output exceeded ${CAPTURE_BYTES} bytes`;return record;}
 const line=stderr.split('\n').filter(candidate=>candidate.startsWith('HEAVY_GATE ')).at(-1);
 if(!line){record.error=`heavy gate produced no record (exit ${settled.code})`;return record;}
 let gate;
 try{gate=JSON.parse(line.slice('HEAVY_GATE '.length));}catch(error){record.error=`heavy gate record is not JSON: ${String(error)}`;return record;}
 record.gate=gate;
 if(gate.status!=='PASS'||gate.reportPhase!=='complete'||gate.ownedTreeStopped!==true||gate.exitCode!==0||settled.code!==0){
  const reason=gate.reason?`, reason ${gate.reason}`:'';
  record.error=`heavy gate ${gate.status} (phase ${gate.reportPhase}, ownedTreeStopped ${gate.ownedTreeStopped}, commandExitCode ${gate.commandExitCode}, exit ${gate.exitCode}${reason})`;
  return record;
 }
 record.status='PASS';
 return record;
}

async function main(){
 let parsed;
 try{parsed=parseArguments(process.argv.slice(2));}
 catch(error){console.error(`g24_source_smoke: ${error.message}\n\n${USAGE}`);process.exitCode=2;return;}
 if(parsed.help){console.log(USAGE);return;}
 const {config,fixtures}=parsed;
 const directory=mkdtempSync(join(tmpdir(),'bend-g24-source-smoke-'));
 const receiptPath=config.receipt??join(directory,'receipt.json');
 const report={schemaVersion:1,status:'RUNNING',
  scope:'Integrated changed-path Bend source smoke: canonical engine emission, clang -O1 C build, and C/JS consumers matched against exact #| lines. Not selfhost compiler acceptance, not byte fixedpoint, and not a replacement for any existing gate.',
  compilerAccepted:false,byteFixedpoint:false,fullAcceptance:false,
  limits:{...LIMITS},directory,receiptPath,repoRoot:REPO_ROOT,targets:config.targets,fixtures:[],runtime:null,harness:null,compiler:null,rows:[],startedAt:new Date().toISOString()};
 const save=()=>writeFileSync(receiptPath,JSON.stringify(report,null,2)+'\n');
 save();
 try{
  if(process.versions.bun)
   throw Error('run this driver with node; it emits and runs consumers with the node executable and only uses bun for evals/heavy_gate.ts');
  if(process.env.HEAVY_GATE_LEASE_TOKEN||process.env.HEAVY_GATE_LEASE_PATH)
   throw Error('this driver already guards every stage; invoke it directly rather than inside evals/heavy_gate.ts');
  if(!existsSync(GATE))throw Error('missing evals/heavy_gate.ts');
  report.runtime={
   node:await runtimeIdentity(config.node,['--version'],'node'),
   bun:await runtimeIdentity(config.bun,['--version'],'bun'),
   clang:await runtimeIdentity(config.clang,['--version'],'clang'),
  };
  report.harness=await hashPaths(['evals/g24_source_smoke.mjs','evals/g24_source_smoke_worker.mjs','evals/heavy_gate.ts','evals/heavy_gate_native.c']);
  report.compiler=await hashPaths(['bend2/bend.ts','bend2/comp.ts','bend2/base.bend']);
  report.generatedInputs=await hashGenerated(['checkpoints/checker_core_steps_v1.bend','checkpoints/checker_core_steps_component_v1.bend','checkpoints/checker_core_steps_driver_v1.bend','checkpoints/emitter_steps_v1.bend']);
  const sources=fixtures.map(repositorySource);
  const seen=new Set();
  for(const source of sources){
   if(seen.has(source))throw Error(`duplicate fixture: ${relative(REPO_ROOT,source)}`);
   seen.add(source);
  }
  report.fixtures=sources.map(source=>relative(REPO_ROOT,source));
  save();
  const inputPins=new Map();
  for(const [index,source] of sources.entries()){
   const sourceText=readFileSync(source,'utf8');
   const expected=expectationsOf(sourceText,source);
   const sourceSha256=await shaFile(source);
   for(const target of config.targets){
    const row={index,source:relative(REPO_ROOT,source),absoluteSource:source,target,sourceSha256,expected,stages:{},passed:false};
    report.rows.push(row);
    save();
    const stem=`${String(index).padStart(3,'0')}-${basename(source,'.bend')}`;
    const output=join(directory,`${stem}.${target}`);
    const emit=await runGuarded(report.runtime.bun.path,`emit ${target} ${row.source}`,[report.runtime.node.path,'--experimental-strip-types',WORKER,source,output]);
    row.stages.emit=emit;
    save();
    if(emit.status!=='PASS')throw Error(`emission failed for ${row.source} (${target}): ${emit.error}`);
    if(!existsSync(output))throw Error(`emission produced no ${target} output for ${row.source}`);
    row.outputSha256=await shaFile(output);
    row.outputBytes=statSync(output).size;
    const manifest=JSON.parse(readFileSync(output+'.inputs.json','utf8'));
    if(manifest.schemaVersion!==1||manifest.source!==source||manifest.target!==target||!Array.isArray(manifest.inputs))
     throw Error(`invalid emission input manifest for ${row.source} (${target})`);
    row.inputs=manifest.inputs;
    if(!row.inputs.some(input=>input.path===source&&input.sha256===sourceSha256))
     throw Error(`emission manifest does not authenticate ${row.source}`);
    for(const input of row.inputs){
     if(typeof input.path!=='string'||!isAbsolute(input.path)||!/^[0-9a-f]{64}$/.test(input.sha256))
      throw Error(`invalid emission input pin for ${row.source}`);
     if(inputPins.has(input.path)&&inputPins.get(input.path)!==input.sha256)
      throw Error(`input differs between smoke emissions: ${input.path}`);
     if(await shaFile(input.path)!==input.sha256)
      throw Error(`emission input changed: ${input.path}`);
     inputPins.set(input.path,input.sha256);
    }
    save();
    let consumerCommand;
    if(target==='c'){
     const executable=output+'.exe';
     const clang=await runGuarded(report.runtime.bun.path,`clang ${row.source}`,[report.runtime.clang.path,'-std=c11','-O1','-pthread',output,'-lm','-o',executable]);
     row.stages.clang=clang;
     save();
     if(clang.status!=='PASS')throw Error(`C build failed for ${row.source}: ${clang.error}`);
     if(!existsSync(executable))throw Error(`C build produced no executable for ${row.source}`);
     row.executableSha256=await shaFile(executable);
     row.executableBytes=statSync(executable).size;
     save();
     consumerCommand=[executable];
    }else consumerCommand=[report.runtime.node.path,'--max-old-space-size=3072',output];
    const consumer=await runGuarded(report.runtime.bun.path,`run ${target} ${row.source}`,consumerCommand,expected);
    row.stages.consumer=consumer;
    row.observed=consumer.stdout;
    save();
    if(consumer.status!=='PASS')throw Error(`consumer failed for ${row.source} (${target}): ${consumer.error}`);
    row.passed=consumer.outputMatches===true;
    save();
    if(!row.passed)throw Error(`consumer output differs from #| expectations for ${row.source} (${target})`);
   }
  }
  for(const [path,hash] of Object.entries(report.compiler))
   if(await shaFile(resolve(REPO_ROOT,path))!==hash)throw Error(`compiler source changed during the smoke: ${path}`);
  for(const [path,hash] of Object.entries(report.harness))
   if(await shaFile(resolve(REPO_ROOT,path))!==hash)throw Error(`harness source changed during the smoke: ${path}`);
  for(const [path,hash] of Object.entries(report.generatedInputs))
   if(await shaFile(resolve(REPO_ROOT,path))!==hash)throw Error(`generated step input changed during the smoke (regenerate before invoking): ${path}`);
  for(const row of report.rows)
   if(await shaFile(row.absoluteSource)!==row.sourceSha256)throw Error(`fixture changed during the smoke: ${row.source}`);
  for(const [path,hash] of inputPins)
   if(await shaFile(path)!==hash)throw Error(`transitive emission input changed during the smoke: ${path}`);
  report.status='SOURCE_CHANGED_PATH_SMOKE_PASS';
  report.finishedAt=new Date().toISOString();
  save();
  console.log(JSON.stringify({status:report.status,receipt:receiptPath,rows:report.rows.length}));
 }catch(error){
  report.status='FAIL';
  report.error=String(error?.message??error);
  report.stack=error?.stack;
  report.finishedAt=new Date().toISOString();
  save();
  console.error(`g24_source_smoke FAIL: ${report.error}\nreceipt: ${receiptPath}`);
  process.exitCode=1;
 }
}

await main();
