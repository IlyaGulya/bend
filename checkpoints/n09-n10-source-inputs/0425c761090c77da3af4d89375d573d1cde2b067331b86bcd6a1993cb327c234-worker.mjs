// Diagnostic adaptation of evals/compiler_codegen_probe.ts lifecycle.
// Existing observer seam only. Stops at pass-2 or earlier convergence before C rendering; never changes the compiler.
import {createHash} from 'node:crypto';
import {readFileSync, writeFileSync, openSync, closeSync, appendFileSync, renameSync, realpathSync} from 'node:fs';
import {dirname, resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
const [planPath, tag, reportPath] = process.argv.slice(2);
if (!planPath || !['R12','G39'].includes(tag) || !reportPath || process.argv.length !== 5) throw Error('Expected PLAN R12|G39 FRESH_REPORT');
const hash = path => createHash('sha256').update(readFileSync(path)).digest('hex');
const plan = JSON.parse(readFileSync(planPath, 'utf8'));
const lane = plan.lanes[tag];
const pins = [...plan.toolPins, ...lane.inputs];
function authenticate() {
  for (const x of pins) if (hash(x.path) !== x.sha256) throw Error('Input drift: '+x.path);
  if (process.env.BUN_JSC_forceRAMSize !== plan.environment.BUN_JSC_forceRAMSize) throw Error('Accepted-control GC RAM hint missing');
  if (!process.versions.bun || process.versions.bun !== plan.bun.version || hash(process.execPath) !== plan.bun.sha256) throw Error('Wrong Bun producer');
  if (process.execArgv.length) throw Error('Original codegen child must have empty execArgv');
}
authenticate();
const {guardHeavyGate} = await import(pathToFileURL(plan.guardSource).href);
await guardHeavyGate(import.meta.path, {label:'N09 matched accepted-env bounded construction'});
const {createCompileBookObserver} = await import(pathToFileURL(plan.observerSource).href);
closeSync(openSync(reportPath, 'wx'));
const eventPath=reportPath+'.events.jsonl', fd=openSync(eventPath,'wx');
const eventDigest=createHash('sha256');
let phase='load', codegenStart=0, pass=0, sequence=0, passFacts=null;
const started=performance.now();
const report={schemaVersion:1,status:'IN_PROGRESS',terminal:false,diagnosticOnly:true,acceptanceEvidence:false,
  compilerAccepted:false,outputPublished:false,tag,source:lane.root,bridge:lane.bridge,
  plan:{path:planPath,sha256:hash(planPath)},eventPath,limits:plan.prefix,
  runtime:{pid:process.pid,ppid:process.ppid,execPath:process.execPath,argv:process.argv,execArgv:process.execArgv,versions:process.versions,
    environment:Object.fromEntries(Object.entries(process.env).filter(([k])=>/^(BUN_JSC_|JSC_|BUN_OPTIONS$|NODE_OPTIONS$|BEND_LIB$|BEND_HUB$)/.test(k))),
    automaticGcRamHint:{bytes:process.env.BUN_JSC_forceRAMSize,hardLimit:false},manualGC:false},
  checkedDefinitions:null,eventsFullyValidated:null,checksExcluded:0,outputPatches:0,passRows:[],changedOriginEvents:[],memorySamples:[],stageCounts:{}};
function save(){ report.elapsedMs=performance.now()-started;report.phase=phase;writeFileSync(reportPath+'.tmp',JSON.stringify(report,null,2)+'\n');renameSync(reportPath+'.tmp',reportPath); }
function event(stage,name,state={}) {
  const boundary=stage.startsWith('c-pass-')||stage.startsWith('c-reachability-');
  const changed=plan.changedDeclarations.some(d=>name.endsWith('emitter_body_'+d));
  const row={sequence:++sequence,stage,name,pass,phase,state};
  report.stageCounts[stage]=(report.stageCounts[stage]??0)+1;
  if(boundary||changed||sequence%plan.logging.memoryEveryEvents===0){
    row.unixMs=Date.now();row.elapsedMs=performance.now()-started;
    row.codegenElapsedMs=codegenStart?performance.now()-codegenStart:null;
    row.processMemory=process.memoryUsage();row.processCpuUs=process.cpuUsage();
    report.memorySamples.push(row);
  }
  const encoded=JSON.stringify(row)+'\n';
  appendFileSync(fd,encoded);eventDigest.update(encoded);
  report.last=row;
  if(changed){
    report.changedOriginEventCount=(report.changedOriginEventCount??0)+1;
    if(report.changedOriginEvents.length<32)report.changedOriginEvents.push(row);
  }
  if(boundary||sequence%plan.logging.saveEveryEvents===0)save();
  return row;
}
class ProbeStop extends Error{}
let kernel;
try {
  save();
  const K=await import(pathToFileURL(resolve(lane.directory,'bend2/bend.ts')).href);
  const C=await import(pathToFileURL(resolve(lane.directory,'bend2/comp.ts')).href);kernel=K;
  const expected=new Map(lane.inputs.map(x=>[realpathSync(x.path),x.sha256]));
  const observed=new Set();
  function pinLoaded(path){
    const real=realpathSync(path), digest=expected.get(real);
    if(!digest)throw Error('Unmanifested source dependency: '+real);
    if(hash(real)!==digest)throw Error('Loaded source drift: '+real);
    observed.add(real);
  }
  class Inputs extends Map {
    set(path,namespace){if(namespace===null)pinLoaded(path);return super.set(path,namespace);}
  }
  const book=K.book_nil(),seen=new Inputs();
  await K.book_load(book,lane.root,'',seen);
  await K.book_load(book,lane.bridge,'',seen,undefined,dirname(lane.root)+'/');
  for(const definition of Object.values(book.tlds))if(definition.$==='Def')for(const path of definition.i??[])pinLoaded(path);
  report.loadedInputs=[...observed].sort();
  event('loaded','',{bookEvents:book.order.length,modules:seen.size});
  phase='validate';save();
  const expectedDefinitions=Object.values(book.tlds).filter(d=>d.$==='Def'&&d.v!==null).length;
  K.book_valid(book);
  if(book.hols)throw Error('Canonical validation left holes');
  let checked=0;
  for(const d of Object.values(book.tlds))if(d.$==='Def'&&d.v!==null){if(d.e===undefined)throw Error('Missing checked body');checked++;}
  if(checked!==expectedDefinitions || checked!==plan.expectedCheckedDefinitions || book.order.length!==plan.expectedBookEvents)throw Error('Full validation coverage mismatch');
  report.checkedDefinitions=checked;report.eventsFullyValidated=book.order.length;
  phase='codegen';codegenStart=performance.now();
  event('validated','',{checkedDefinitions:checked,bookEvents:book.order.length});save();
  const observer=createCompileBookObserver(undefined,{onEvent(stage,name,state){
    const boundary=/^c-pass-(\d+)-(before|after)$/.exec(stage);
    if(boundary)pass=Number(boundary[1]);
    const row=event(stage,name,state);
    if(boundary?.[2]==='before')passFacts=state.ownFacts+state.hotFacts+state.staticFacts;
    if(boundary?.[2]==='after')report.passRows.push(row);
    if(boundary?.[2]==='after'&&passFacts===state.ownFacts+state.hotFacts+state.staticFacts)throw new ProbeStop('converged-pass-boundary-before-C-render');
    if(boundary?.[2]==='after'&&pass>=plan.prefix.passes)throw new ProbeStop('pass-budget');
    if(sequence>=plan.prefix.events)throw new ProbeStop('observer-event-budget');
    if(performance.now()-codegenStart>=plan.prefix.codegenMs)throw new ProbeStop('codegen-time-budget');
  }});
  C.compile_book(book,{observe:observer.observe});
  throw Error('Unreachable C rendering reached: bounded observation contract violated');
}catch(error){
  report.status=error instanceof ProbeStop?'PROBE_STOPPED':'FAIL';
  report.reason=kernel&&error?.$==='Err'?kernel.err_show(error):String(error?.message??error);
  try{authenticate();}catch(drift){report.status='FAIL';report.reason=String(drift);}
  if(report.status==='FAIL')process.exitCode=2;
}finally{
  closeSync(fd);report.eventSha256=eventDigest.digest('hex');report.observerEvents=sequence;
  report.codegenMs=codegenStart?performance.now()-codegenStart:null;report.terminal=true;save();
  console.log('N09_PROBE_RESULT '+JSON.stringify({tag,status:report.status,reason:report.reason,report:reportPath,events:sequence}));
}
