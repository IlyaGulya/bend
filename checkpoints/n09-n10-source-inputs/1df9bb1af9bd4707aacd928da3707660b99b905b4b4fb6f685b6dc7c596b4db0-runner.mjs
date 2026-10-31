// N10: four distinct construction cells, once each, serial original guards.
import {createHash} from 'node:crypto';
import {readFileSync,writeFileSync,mkdirSync,existsSync} from 'node:fs';
import {resolve,dirname} from 'node:path';
import {pathToFileURL,fileURLToPath} from 'node:url';
const [planPath,out]=process.argv.slice(2);
if(!planPath||!out||process.argv.length!==4||existsSync(out))throw Error('Expected PLAN FRESH_OUTPUT_DIRECTORY');
if(process.env.HEAVY_GATE_LEASE_TOKEN||process.env.HEAVY_GATE_LEASE_PATH)throw Error('Matrix owns original guard once per cell');
const here=dirname(fileURLToPath(import.meta.url));
const plan=JSON.parse(readFileSync(planPath,'utf8'));
const hash=path=>createHash('sha256').update(readFileSync(path)).digest('hex');
function authenticate(){
 for(const x of [...plan.toolPins,...Object.values(plan.lanes).flatMap(l=>l.inputs)])if(hash(x.path)!==x.sha256)throw Error('Frozen input drift: '+x.path);
 if(hash(plan.bun.path)!==plan.bun.sha256||process.versions.bun!==plan.bun.version)throw Error('Wrong Bun producer');
}
authenticate();
const inheritedRuntimeEnvironment=Object.fromEntries(Object.entries(process.env).filter(([k])=>/^(BUN_JSC_|JSC_|BUN_OPTIONS$|NODE_OPTIONS$|BEND_LIB$|BEND_HUB$)/.test(k)));
const conflicts=Object.keys(inheritedRuntimeEnvironment).filter(k=>/^(BUN_JSC_|JSC_|BUN_OPTIONS$|NODE_OPTIONS$)/.test(k)&&k!=='BUN_JSC_forceRAMSize');
if(conflicts.length)throw Error('Unpredeclared runtime environment: '+conflicts.join(','));
mkdirSync(out,{recursive:false});
const result={schemaVersion:1,experiment:'N10',status:'IN_PROGRESS',diagnosticOnly:true,compilerAccepted:false,performanceAccepted:false,newFixedpointClaim:false,
 plan:{path:planPath,sha256:hash(planPath)},axis:plan.axis,guard:plan.guard,targetEvent:plan.targetEvent,inheritedRuntimeEnvironment,cells:[],allCellsExecuted:false};
const save=()=>writeFileSync(resolve(out,'receipt.json'),JSON.stringify(result,null,2)+'\n');save();
const {runHeavyGate}=await import(pathToFileURL(plan.guardSource).href);
for(const cell of plan.cases){
 authenticate();
 if(cell.gcRamHint===null)delete process.env.BUN_JSC_forceRAMSize;else process.env.BUN_JSC_forceRAMSize=cell.gcRamHint;
 const report=resolve(out,cell.id+'.json');
 const command=[plan.bun.path,resolve(here,'worker.mjs'),planPath,cell.id,report];
 const guardian=await runHeavyGate(command,{...plan.guard,label:'N10 '+cell.id+' literal-boundary environment intervention'});
 if(guardian.reportPhase!=='complete'||!guardian.ownedTreeStopped)throw Error('Previous heavy tree not settled; do not start another cell');
 let data=null;
 if(existsSync(report)&&readFileSync(report,'utf8').trim())data=JSON.parse(readFileSync(report,'utf8'));
 const t=plan.targetEvent;
 const reached=guardian.status==='PASS'&&data?.terminal&&data.status==='PROBE_STOPPED'&&data.reason==='target-literal-boundary'&&data.last?.sequence===t.sequence&&data.last?.stage===t.stage&&data.last?.name.endsWith(t.nameSuffix)&&data.last?.pass===t.pass;
 const status=reached?'TARGET_REACHED':guardian.status==='RESOURCE_LIMIT'?'RESOURCE_LIMIT_BEFORE_TARGET':'FAIL_BEFORE_TARGET';
 const r={...cell,status,targetReached:reached,command,guardian,report,reportSha256:existsSync(report)?hash(report):null,
  workerStatus:data?.status??'NO_WORKER_REPORT',workerTerminal:data?.terminal??false,workerReason:data?.reason??null,
  runtime:data?.runtime??null,checkedDefinitions:data?.checkedDefinitions??null,eventsFullyValidated:data?.eventsFullyValidated??null,
  loadedInputs:data?.loadedInputs??[],observerEvents:data?.observerEvents??data?.last?.sequence??null,
  eventPath:data?.eventPath??null,eventSha256:data?.eventSha256??null,last:data?.last??null,
  changedOriginEvents:data?.changedOriginEvents??[],passRows:data?.passRows??[],stageCounts:data?.stageCounts??{},
  codegenMs:data?.codegenMs??null,noCOutputPublished:data?.outputPublished===false};
 result.cells.push(r);authenticate();save();
 console.log('N10_CELL '+JSON.stringify({id:cell.id,status,events:r.observerEvents,peakRssBytes:guardian.peakRssBytes,peakFootprintBytes:guardian.peakFootprintBytes}));
}
result.allCellsExecuted=result.cells.length===plan.cases.length;
const hint=result.cells.filter(c=>c.gcRamHint!==null),unset=result.cells.filter(c=>c.gcRamHint===null);
result.status=hint.every(c=>c.targetReached)&&unset.every(c=>c.status==='RESOURCE_LIMIT_BEFORE_TARGET')?'GO_OBSERVED_GC_HINT_DEPENDENCE_BOTH_SOURCES':
 hint.every(c=>c.targetReached)&&unset.some(c=>c.status==='RESOURCE_LIMIT_BEFORE_TARGET')?'GO_INSPECT_SOURCE_HINT_INTERACTION':
 result.cells.every(c=>c.targetReached)?'STOP_HINT_NOT_NECESSARY_AT_OBSERVED_BOUNDARY':'STOP_UNRESOLVED_MATRIX_PATTERN';
result.interpretation='Single predeclared source/environment matrix, not a timing benchmark, statistical replication, historical environment recovery, hard heap quota, native qualification, or permission to change semantic IR.';
authenticate();save();
console.log('N10_RESULT '+JSON.stringify({status:result.status,receipt:resolve(out,'receipt.json')}));
