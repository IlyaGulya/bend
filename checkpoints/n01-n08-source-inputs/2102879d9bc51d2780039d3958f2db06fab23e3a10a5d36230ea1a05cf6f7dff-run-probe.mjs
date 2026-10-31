// Parent-only execution. One fixed source-axis experiment, two serial bounded lanes.
import {createHash} from 'node:crypto';
import {readFileSync, writeFileSync, mkdirSync, existsSync} from 'node:fs';
import {resolve, dirname} from 'node:path';
import {fileURLToPath, pathToFileURL} from 'node:url';
const here=dirname(fileURLToPath(import.meta.url));
const planPath=resolve(here,'n04-plan.json');
const plan=JSON.parse(readFileSync(planPath,'utf8'));
const out=process.argv[2];
if(!out || process.argv.length!==3 || existsSync(out))throw Error('Expected one FRESH_OUTPUT_DIRECTORY');
if(process.env.HEAVY_GATE_LEASE_TOKEN || process.env.HEAVY_GATE_LEASE_PATH)throw Error('Do not wrap this runner: it owns each guard once');
const hash=path=>createHash('sha256').update(readFileSync(path)).digest('hex');
function authenticate(){
  for(const x of [...plan.toolPins,...Object.values(plan.lanes).flatMap(l=>l.inputs)])if(hash(x.path)!==x.sha256)throw Error('Frozen input drift: '+x.path);
  if(hash(plan.bun.path)!==plan.bun.sha256 || !process.versions.bun || process.versions.bun!==plan.bun.version)throw Error('Use pinned original Bun');
}
authenticate();
const inheritedRuntimeEnvironment=Object.fromEntries(Object.entries(process.env).filter(([k])=>/^(BUN_JSC_|JSC_|BUN_OPTIONS$|NODE_OPTIONS$|BEND_LIB$|BEND_HUB$)/.test(k)));
const conflicting=Object.keys(inheritedRuntimeEnvironment).filter(k=>/^(BUN_JSC_|JSC_|BUN_OPTIONS$|NODE_OPTIONS$)/.test(k)&&k!=='BUN_JSC_forceRAMSize');
if(conflicting.length)throw Error('Unpredeclared runtime environment: '+conflicting.join(','));
// Explicit matched accepted-control environment. A GC heuristic, never a hard heap cap.
process.env.BUN_JSC_forceRAMSize=plan.environment.BUN_JSC_forceRAMSize;
mkdirSync(out,{recursive:false});
const result={schemaVersion:1,status:'IN_PROGRESS',diagnosticOnly:true,compilerAccepted:false,acceptanceEvidence:false,
  axis:plan.axis,plan:{path:planPath,sha256:hash(planPath)},inheritedRuntimeEnvironment,
  selectedEnvironment:plan.environment,lanes:[],structuralComparison:null,physicalComparison:null};
const save=()=>writeFileSync(resolve(out,'receipt.json'),JSON.stringify(result,null,2)+'\n');
save();
const {runHeavyGate}=await import(pathToFileURL(plan.guardSource).href);
for(const tag of ['R12','G39']) {
  authenticate();
  const report=resolve(out,tag+'.json');
  const command=[plan.bun.path,resolve(here,'probe-worker.mjs'),planPath,tag,report];
  const guardian=await runHeavyGate(command,{...plan.guard,label:'N04 '+tag+' matched accepted-env bounded source prefix'});
  let data=null;
  if(existsSync(report)&&readFileSync(report,'utf8').trim())data=JSON.parse(readFileSync(report,'utf8'));
  result.lanes.push({tag,command,guardian,report,reportSha256:existsSync(report)?hash(report):null,
    status:data?.status??'NO_WORKER_REPORT',terminal:data?.terminal??false,checkedDefinitions:data?.checkedDefinitions??null,
    eventsFullyValidated:data?.eventsFullyValidated??null,last:data?.last??null,changedOriginEvents:data?.changedOriginEvents??null});
  save();
  if(guardian.status!=='PASS'||guardian.reportPhase!=='complete'||!guardian.ownedTreeStopped||!data?.terminal||!['PROBE_STOPPED','CODEGEN_SETTLED'].includes(data.status)) {
    result.status=tag==='R12'?'STOP_CONTROL_CONSTRUCTION_BLOCKER':'STOP_CANDIDATE_INCOMPLETE_PREFIX';
    result.interpretation='Do not retry unchanged, increase caps, infer GC cause, or accept a source fix. Keep all partial events.';
    save();process.exitCode=2;break;
  }
}
if(result.lanes.length===2 && result.lanes.every(l=>l.guardian.status==='PASS'&&l.terminal&&['PROBE_STOPPED','CODEGEN_SETTLED'].includes(l.status))) {
  const events=tag=>readFileSync(resolve(out,tag+'.json.events.jsonl'),'utf8').trim().split('\n').filter(Boolean).map(line=>JSON.parse(line));
  const a=events('R12'),b=events('G39');
  const normalize=name=>name.replaceAll(plan.lanes.R12.directory,'<INPUT>').replaceAll(plan.lanes.G39.directory,'<INPUT>').replace(/local2039g(?:24r12|39e12full01)/g,'<RUN>');
  const stable=x=>JSON.stringify(Object.entries(x).sort(([a],[b])=>a.localeCompare(b)));
  let first=null,matched=0;
  for(let i=0;i<Math.min(a.length,b.length);i++){
    const x=a[i],y=b[i];
    const alignment=x.stage===y.stage&&normalize(x.name)===normalize(y.name)&&x.pass===y.pass;
    const structural=stable(x.state)===stable(y.state);
    if(!alignment||!structural){first={index:i,kind:alignment?'STRUCTURAL_STATE':'ORDER_OR_NAME',control:x,candidate:y};break;}
    matched++;
  }
  result.structuralComparison={matchedPrefixEvents:matched,firstDivergence:first,controlEvents:a.length,candidateEvents:b.length,
    changedOriginsObserved:Object.fromEntries(result.lanes.map(l=>[l.tag,Boolean(l.changedOriginEvents?.length)])),
    sourceShape:plan.shapeDelta,rawNamesPreserved:true,normalization:'Only lane absolute paths and explicit root run-id spelling for alignment'};
  result.physicalComparison=Object.fromEntries(result.lanes.map(l=>[l.tag,{peakRssBytes:l.guardian.peakRssBytes,peakFootprintBytes:l.guardian.peakFootprintBytes,elapsedMs:l.guardian.elapsedMs}]));
  const changedOriginReached=result.lanes.every(l=>l.changedOriginEvents?.length);
  result.status=!changedOriginReached?'STOP_CHANGED_ORIGIN_NOT_OBSERVED':first?'GO_LOCALIZE_STRUCTURAL_DIVERGENCE_NOT_SOURCE_FIX':'STOP_NO_STRUCTURAL_DIVERGENCE_IN_OBSERVED_PREFIX';
  result.interpretation=!changedOriginReached?'Changed source origin was not observed in both prefixes; no source-runtime causal attribution. Preserve any earlier structural mismatch as an observation, not a fix rationale.':first?'Inspect first differing declaration/pass and map to authenticated source origin; a single instrumented pair does not establish stability, retained bytes, performance acceptance, or authorize production edits.':'Equal structural prefix does not prove equal later execution or GC causality.';
  authenticate();save();
}
console.log('N04_RESULT '+JSON.stringify({status:result.status,receipt:resolve(out,'receipt.json')}));
