// N09: original guardian, two serial source lanes, bounded streaming comparison.
import {createHash} from 'node:crypto';
import {readFileSync,writeFileSync,mkdirSync,existsSync,createReadStream} from 'node:fs';
import {resolve,dirname} from 'node:path';
import {pathToFileURL,fileURLToPath} from 'node:url';
import {createInterface} from 'node:readline';
const [planPath,out]=process.argv.slice(2);
if(!planPath||!out||process.argv.length!==4||existsSync(out))throw Error('Expected PLAN FRESH_OUTPUT_DIRECTORY');
if(process.env.HEAVY_GATE_LEASE_TOKEN||process.env.HEAVY_GATE_LEASE_PATH)throw Error('Runner owns original guard once per lane');
const here=dirname(fileURLToPath(import.meta.url));
const plan=JSON.parse(readFileSync(planPath,'utf8'));
const hash=path=>createHash('sha256').update(readFileSync(path)).digest('hex');
function authenticate(){
 for(const x of [...plan.toolPins,...Object.values(plan.lanes).flatMap(l=>l.inputs)])if(hash(x.path)!==x.sha256)throw Error('Frozen input drift: '+x.path);
 if(hash(plan.bun.path)!==plan.bun.sha256||process.versions.bun!==plan.bun.version)throw Error('Wrong Bun producer');
}
authenticate();
const inheritedRuntimeEnvironment=Object.fromEntries(Object.entries(process.env).filter(([k])=>/^(BUN_JSC_|JSC_|BUN_OPTIONS$|NODE_OPTIONS$|BEND_LIB$|BEND_HUB$)/.test(k)));
const conflicting=Object.keys(inheritedRuntimeEnvironment).filter(k=>/^(BUN_JSC_|JSC_|BUN_OPTIONS$|NODE_OPTIONS$)/.test(k)&&k!=='BUN_JSC_forceRAMSize');
if(conflicting.length)throw Error('Unpredeclared runtime environment: '+conflicting.join(','));
process.env.BUN_JSC_forceRAMSize=plan.environment.BUN_JSC_forceRAMSize;
mkdirSync(out,{recursive:false});
const result={schemaVersion:1,experiment:'N09',status:'IN_PROGRESS',diagnosticOnly:true,compilerAccepted:false,performanceAccepted:false,newFixedpointClaim:false,axis:plan.axis,plan:{path:planPath,sha256:hash(planPath)},inheritedRuntimeEnvironment,selectedEnvironment:plan.environment,lanes:[],comparison:null};
const save=()=>writeFileSync(resolve(out,'receipt.json'),JSON.stringify(result,null,2)+'\n');
save();
const {runHeavyGate}=await import(pathToFileURL(plan.guardSource).href);
for(const tag of ['R12','G39']){
 authenticate();
 const report=resolve(out,tag+'.json');
 const command=[plan.bun.path,resolve(here,'worker.mjs'),planPath,tag,report];
 const guardian=await runHeavyGate(command,{...plan.guard,label:'N09 '+tag+' matched source through second pass or convergence'});
 let data=null;
 if(existsSync(report)&&readFileSync(report,'utf8').trim())data=JSON.parse(readFileSync(report,'utf8'));
 result.lanes.push({tag,command,guardian,report,reportSha256:existsSync(report)?hash(report):null,
  status:data?.status??'NO_WORKER_REPORT',terminal:data?.terminal??false,reason:data?.reason??null,
  runtime:data?.runtime??null,checkedDefinitions:data?.checkedDefinitions??null,eventsFullyValidated:data?.eventsFullyValidated??null,
  observerEvents:data?.observerEvents??null,eventPath:data?.eventPath??null,eventSha256:data?.eventSha256??null,
  loadedInputs:data?.loadedInputs??[],passRows:data?.passRows??[],stageCounts:data?.stageCounts??{},
  changedOriginEvents:data?.changedOriginEvents??[],last:data?.last??null,codegenMs:data?.codegenMs??null,
  noCOutputPublished:data?.outputPublished===false});
 save();
 const complete=guardian.status==='PASS'&&guardian.reportPhase==='complete'&&guardian.ownedTreeStopped&&data?.terminal&&data.status==='PROBE_STOPPED';
 if(!complete){
  result.status=tag==='R12'?'STOP_CONTROL_BLOCKER':'STOP_CANDIDATE_INCOMPLETE_BOUNDARY';
  result.interpretation='Preserve partial events. Never retry unchanged, raise caps or call a missing boundary passed.';
  save();process.exitCode=2;break;
 }
}
// Compare scalar event streams with bounded memory, including partial candidate logs.
if(result.lanes.length===2&&result.lanes.every(l=>l.eventPath&&existsSync(l.eventPath))){
 const normalize=name=>name.replaceAll(plan.lanes.R12.directory,'<INPUT>').replaceAll(plan.lanes.G39.directory,'<INPUT>').replace(/local2039g(?:24r12|39e12full01)/g,'<RUN>');
 const stable=s=>JSON.stringify(Object.entries(s).sort(([a],[b])=>a.localeCompare(b)));
 const streams=result.lanes.map(l=>createReadStream(l.eventPath,{encoding:'utf8'}));
 const lines=streams.map(input=>createInterface({input,crlfDelay:Infinity}));
 const iterators=lines.map(l=>l[Symbol.asyncIterator]());
 let compared=0,matchedPrefix=0,first=null,lastPair=null,unaligned=null,structuralMismatchEvents=0;
 const priorPairs=[],numericDeltaRanges={},passSummaries={};
 try{
  while(true){
   const [a,b]=await Promise.all(iterators.map(it=>it.next()));
   if(a.done||b.done){result.comparisonEnd={controlDone:a.done,candidateDone:b.done};break;}
   if(!a.value||!b.value)throw Error('Unexpected blank event row');
   const x=JSON.parse(a.value),y=JSON.parse(b.value);
   const aligned=x.sequence===y.sequence&&x.stage===y.stage&&normalize(x.name)===normalize(y.name)&&x.pass===y.pass;
   const same=stable(x.state)===stable(y.state);
   const key={sequence:x.sequence,stage:x.stage,name:normalize(x.name),pass:x.pass};
   const fields=[];
   if(aligned&&!same){
    structuralMismatchEvents++;
    for(const k of new Set([...Object.keys(x.state),...Object.keys(y.state)])){
     if(JSON.stringify(x.state[k])===JSON.stringify(y.state[k]))continue;
     fields.push({field:k,control:x.state[k]??null,candidate:y.state[k]??null});
     if(typeof x.state[k]==='number'&&typeof y.state[k]==='number'){
      const d=y.state[k]-x.state[k],range=numericDeltaRanges[k]??{min:d,max:d,first:key,last:key};
      range.min=Math.min(range.min,d);range.max=Math.max(range.max,d);range.last=key;numericDeltaRanges[k]=range;
     }
    }
   }
   if(!first&&(!aligned||!same))first={kind:aligned?'STRUCTURAL_STATE':'ORDER_OR_NAME',control:x,candidate:y,differingFields:fields,precedingPairs:priorPairs.slice()};
   if(!first)matchedPrefix++;
   compared++;
   lastPair={...key,control:x,candidate:y};
   priorPairs.push({key,controlState:x.state,candidateState:y.state});if(priorPairs.length>4)priorPairs.shift();
   const p=passSummaries[x.pass]??{compared:0,stateMismatchEvents:0,first:key,last:key};p.compared++;p.last=key;if(!same)p.stateMismatchEvents++;passSummaries[x.pass]=p;
   if(!aligned){unaligned=lastPair;break;}
  }
 }finally{lines.forEach(l=>l.close());streams.forEach(s=>s.destroy());}
 result.comparison={comparedEvents:compared,matchedPrefixEvents:matchedPrefix,firstDivergence:first,lastPair,unaligned,structuralMismatchEvents,numericDeltaRanges,passSummaries,
  scope:'Only shared aligned event prefix, structural scalar state, not bytes/heap graph or semantic equivalence',normalization:'Lane directories and explicit historical root run-id spelling only'};
 const bothComplete=result.lanes.every(l=>l.guardian.status==='PASS'&&l.terminal&&l.status==='PROBE_STOPPED');
 if(bothComplete){
  const reached=result.lanes.every(l=>l.observerEvents>50000&&l.passRows.length>0);
  result.status=!reached?'STOP_LATE_BOUNDARY_NOT_REACHED':first?'GO_INSPECT_FIRST_STRUCTURAL_DIFFERENCE_NOT_SOURCE_FIX':'STOP_NO_STRUCTURAL_DIVERGENCE_THROUGH_OBSERVED_PASSES';
 }
 result.interpretation=first?'Localize these exact fields/origins. Expected string-content differences and entry counts are not allocation/retained-byte measurements or a memory-cause proof.':(result.interpretation??'No scalar structural divergence in the compared prefix. Later rendering/runtime GC behavior remains unknown.');
 authenticate();save();
}
console.log('N09_RESULT '+JSON.stringify({status:result.status,receipt:resolve(out,'receipt.json')}));
