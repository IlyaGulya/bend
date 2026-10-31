// N11: smoke first, then four complete source/environment cells, exactly once.
import {createHash} from 'node:crypto';
import {readFileSync,writeFileSync,mkdirSync,existsSync,createReadStream} from 'node:fs';
import {createInterface} from 'node:readline';
import {resolve,dirname} from 'node:path';
import {pathToFileURL,fileURLToPath} from 'node:url';
const [planPath,out]=process.argv.slice(2);
if(!planPath||!out||process.argv.length!==4||existsSync(out))throw Error('Expected PLAN FRESH_DIRECTORY');
if(process.env.HEAVY_GATE_LEASE_TOKEN||process.env.HEAVY_GATE_LEASE_PATH)throw Error('Runner owns original guards');
const plan=JSON.parse(readFileSync(planPath,'utf8')),here=dirname(fileURLToPath(import.meta.url));
const hash=p=>createHash('sha256').update(readFileSync(p)).digest('hex');
function authenticate(){
 for(const x of [...plan.toolPins,...Object.values(plan.lanes).flatMap(l=>l.inputs)])if(hash(x.path)!==x.sha256)throw Error('Input drift: '+x.path);
 for(const x of [plan.bun,plan.node])if(hash(x.path)!==x.sha256)throw Error('Binary drift: '+x.path);
 if(process.versions.bun!==plan.bun.version)throw Error('Wrong Bun parent');
}
authenticate();
const inheritedRuntimeEnvironment=Object.fromEntries(Object.entries(process.env).filter(([k])=>/^(BUN_JSC_|JSC_|BUN_OPTIONS$|NODE_OPTIONS$|BEND_LIB$|BEND_HUB$)/.test(k)));
if(Object.keys(inheritedRuntimeEnvironment).some(k=>/^(BUN_JSC_|JSC_|BUN_OPTIONS$|NODE_OPTIONS$)/.test(k)&&k!=='BUN_JSC_forceRAMSize'))throw Error('Conflicting runtime environment');
mkdirSync(out,{recursive:false});
const result={schemaVersion:1,experiment:'N11',status:'IN_PROGRESS',diagnosticOnly:true,compilerAccepted:false,performanceAccepted:false,newFixedpointClaim:false,plan:{path:planPath,sha256:hash(planPath)},inheritedRuntimeEnvironment,guard:plan.guard,smoke:{},cells:[],allCellsExecuted:false};
const save=()=>writeFileSync(resolve(out,'receipt.json'),JSON.stringify(result,null,2)+'\n');save();
const {runHeavyGate}=await import(pathToFileURL(plan.guardSource).href);
async function guarded(command,label){const g=await runHeavyGate(command,{...plan.guard,label});if(g.reportPhase!=='complete'||!g.ownedTreeStopped)throw Error('Heavy tree not stopped');return {command,guardian:g};}
process.env.BUN_JSC_forceRAMSize='4294967296';
const sr=resolve(out,'smoke.json');
result.smoke.emit=await guarded([plan.bun.path,resolve(here,'smoke.mjs'),planPath,sr],'N11 original/shadow C-byte transparency smoke');save();
if(result.smoke.emit.guardian.status!=='PASS')throw Error('Smoke emit failed');
result.smoke.receipt=JSON.parse(readFileSync(sr,'utf8'));
if(result.smoke.receipt.status!=='PASS_EXACT_ORIGINAL_C_BYTES')throw Error('Smoke C byte equality failed');
const bin=resolve(out,'smoke-native');
result.smoke.clang=await guarded(['/usr/bin/clang','-std=c11','-O1','-pthread',sr+'.c','-lm','-o',bin],'N11 smoke actual C compile');save();
if(result.smoke.clang.guardian.status!=='PASS')throw Error('Smoke C compile failed');
const stdout=resolve(out,'smoke.stdout'),stderr=resolve(out,'smoke.stderr');
result.smoke.execution=await guarded([plan.node.path,plan.captureSource,stdout,stderr,bin],'N11 smoke actual C execution');
result.smoke.actual=readFileSync(stdout,'utf8');result.smoke.expected=plan.smoke.expected;
if(result.smoke.execution.guardian.status!=='PASS'||result.smoke.actual!==plan.smoke.expected)throw Error('Smoke C behavior failed');
result.smoke.status='PASS_EXACT_ORIGINAL_BYTES_AND_ACTUAL_C_CONSUMER';save();
for(const cell of plan.cases){
 authenticate();if(cell.gcRamHint===null)delete process.env.BUN_JSC_forceRAMSize;else process.env.BUN_JSC_forceRAMSize=cell.gcRamHint;
 const report=resolve(out,cell.id+'.json'),command=[plan.bun.path,resolve(here,'worker.mjs'),planPath,cell.id,report];
 const run=await guarded(command,'N11 '+cell.id+' complete C construction');
 let data=null;if(existsSync(report)&&readFileSync(report,'utf8').trim())data=JSON.parse(readFileSync(report,'utf8'));
 let lastProgress=null,progressParseError=null;
 if(data?.eventPath&&existsSync(data.eventPath)){
  const input=createReadStream(data.eventPath,{encoding:'utf8'}),lines=createInterface({input,crlfDelay:Infinity});
  try{for await(const line of lines){try{lastProgress=JSON.parse(line);}catch(e){progressParseError=String(e);break;}}}finally{lines.close();input.destroy();}
 }
 const complete=run.guardian.status==='PASS'&&data?.terminal&&data.status==='COMPLETE_C_CONSTRUCTION'&&data.outputPublished&&data.output?.sha256;
 result.cells.push({...cell,...run,status:complete?'COMPLETE_C_CONSTRUCTION':run.guardian.status==='RESOURCE_LIMIT'?'RESOURCE_LIMIT':'FAIL',report,reportSha256:existsSync(report)?hash(report):null,
 workerStatus:data?.status??'NO_REPORT',workerTerminal:data?.terminal??false,workerReason:data?.reason??null,phase:data?.phase??null,runtime:data?.runtime??null,
 checkedDefinitions:data?.checkedDefinitions??null,eventsFullyValidated:data?.eventsFullyValidated??null,loadedInputs:data?.loadedInputs??[],observerEvents:data?.observerEvents??data?.last?.sequence??null,
 boundaries:data?.boundaries??[],lastSaved:data?.last??null,lastProgress,progressParseError,progressPath:data?.eventPath??null,progressSha256:data?.progressSha256??null,
 structuralTraceSha256:data?.structuralTraceSha256??null,codegenMs:data?.codegenMs??null,publicationMs:data?.publicationMs??null,output:data?.output??null,outputPublished:data?.outputPublished??false,
 expectedAcceptedC:data?.expectedAcceptedC??null});
 authenticate();save();console.log('N11_CELL '+JSON.stringify({id:cell.id,status:result.cells.at(-1).status,lastProgress,output:result.cells.at(-1).output}));
}
result.allCellsExecuted=result.cells.length===plan.cases.length;
result.status=result.cells.every(c=>c.status==='COMPLETE_C_CONSTRUCTION')?'COMPLETE_FULL_CONSTRUCTION_MATRIX':'COMPLETE_MATRIX_WITH_FAILED_CELLS';
result.sameSourceOutputEquality=Object.fromEntries(['R12','G39'].map(tag=>{const a=result.cells.find(c=>c.id===tag+'_hint'),b=result.cells.find(c=>c.id===tag+'_unset');return [tag,a?.output&&b?.output?{comparable:true,byteIdentical:a.output.bytes===b.output.bytes&&a.output.sha256===b.output.sha256}:{comparable:false,byteIdentical:null}];}));
result.interpretation='Complete construction or exact guard failure per cell. No native executable/bootstrap/fixedpoint/paired performance acceptance. Historical environments remain unknown.';
authenticate();save();console.log('N11_RESULT '+JSON.stringify({status:result.status,receipt:resolve(out,'receipt.json')}));
