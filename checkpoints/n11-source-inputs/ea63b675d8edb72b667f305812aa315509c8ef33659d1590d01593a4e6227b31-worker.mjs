// N11: complete canonical book validation and complete C construction.
// Measurement-only seams live in authenticated shadow comp.ts; production stays untouched.
import {createHash} from 'node:crypto';
import {readFileSync,writeFileSync,openSync,closeSync,appendFileSync,renameSync,realpathSync,createReadStream,statSync} from 'node:fs';
import {dirname,resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
const [planPath,caseId,reportPath]=process.argv.slice(2);
if(!planPath||!caseId||!reportPath||process.argv.length!==5)throw Error('Expected PLAN CASE FRESH_REPORT');
const hash=p=>createHash('sha256').update(readFileSync(p)).digest('hex');
const plan=JSON.parse(readFileSync(planPath,'utf8')),cell=plan.cases.find(c=>c.id===caseId);
if(!cell)throw Error('Unknown case');
const lane=plan.lanes[cell.source];
function authenticate(){
 for(const x of [...plan.toolPins,...lane.inputs])if(hash(x.path)!==x.sha256)throw Error('Frozen input drift: '+x.path);
 if(cell.gcRamHint===null?Object.hasOwn(process.env,'BUN_JSC_forceRAMSize'):process.env.BUN_JSC_forceRAMSize!==cell.gcRamHint)throw Error('Hint intervention drift');
 if(process.versions.bun!==plan.bun.version||hash(process.execPath)!==plan.bun.sha256||process.execArgv.length)throw Error('Wrong producer/argv');
}
authenticate();
const {guardHeavyGate}=await import(pathToFileURL(plan.guardSource).href);
await guardHeavyGate(import.meta.path,{label:'N11 complete construction with original guard'});
const {createCompileBookObserver}=await import(pathToFileURL(plan.observerSource).href);
closeSync(openSync(reportPath,'wx'));
const eventPath=reportPath+'.progress.jsonl',fd=openSync(eventPath,'wx');
const traceHash=createHash('sha256'),progressHash=createHash('sha256');
let sequence=0,pass=0,phase='load',codegenStart=0,kernel;
const started=performance.now();
const report={schemaVersion:1,experiment:'N11',status:'IN_PROGRESS',terminal:false,diagnosticOnly:true,compilerAccepted:false,performanceAccepted:false,newFixedpointClaim:false,
 caseId,source:cell.source,gcRamHint:cell.gcRamHint,plan:{path:planPath,sha256:hash(planPath)},eventPath,outputPublished:false,
 runtime:{pid:process.pid,ppid:process.ppid,execPath:process.execPath,argv:process.argv,execArgv:process.execArgv,versions:process.versions,
 environment:Object.fromEntries(Object.entries(process.env).filter(([k])=>/^(BUN_JSC_|JSC_|BUN_OPTIONS$|NODE_OPTIONS$|BEND_LIB$|BEND_HUB$)/.test(k))),manualGC:false},
 checkedDefinitions:null,eventsFullyValidated:null,checksExcluded:0,outputPatches:0,stageCounts:{},boundaries:[],memorySamples:[]};
function save(){report.phase=phase;report.elapsedMs=performance.now()-started;writeFileSync(reportPath+'.tmp',JSON.stringify(report,null,2)+'\n');renameSync(reportPath+'.tmp',reportPath);}
function event(stage,name,state={}){
 const m=/^c-pass-(\d+)-(before|after)$/.exec(stage);if(m)pass=Number(m[1]);
 const key={sequence:++sequence,stage,name,pass};
 report.last=key;report.stageCounts[stage]=(report.stageCounts[stage]??0)+1;
 traceHash.update(JSON.stringify({...key,state})+'\n');
 const fine=/^(prepare|c-definition|c-spin)-/.test(stage)||stage==='release-after';
 const boundary=!fine,changed=plan.changedDeclarations.some(d=>name.endsWith('emitter_body_'+d));
 if(boundary||changed||sequence%plan.logging.memoryEveryEvents===0){
  const row={...key,state,phase,elapsedMs:performance.now()-started,codegenElapsedMs:codegenStart?performance.now()-codegenStart:null,processMemory:process.memoryUsage(),processCpuUs:process.cpuUsage()};
  report.memorySamples.push(row);if(boundary)report.boundaries.push(row);
  const encoded=JSON.stringify(row)+'\n';appendFileSync(fd,encoded);progressHash.update(encoded);
 }else if(stage.endsWith('-before')){
  const encoded=JSON.stringify(key)+'\n';appendFileSync(fd,encoded);progressHash.update(encoded);
 }
 if(boundary||changed||sequence%plan.logging.saveEveryEvents===0)save();
}
try{
 save();
 const K=await import(pathToFileURL(resolve(lane.directory,'bend2/bend.ts')).href);
 const C=await import(pathToFileURL(resolve(lane.directory,'bend2/comp.ts')).href);kernel=K;
 const expected=new Map(lane.inputs.map(x=>[realpathSync(x.path),x.sha256])),observed=new Set();
 function pinLoaded(p){const r=realpathSync(p),h=expected.get(r);if(!h||hash(r)!==h)throw Error('Unmanifested/drifted loaded source: '+r);observed.add(r);}
 class Inputs extends Map{set(p,ns){if(ns===null)pinLoaded(p);return super.set(p,ns);}}
 const book=K.book_nil(),seen=new Inputs();
 await K.book_load(book,lane.root,'',seen);
 await K.book_load(book,lane.bridge,'',seen,undefined,dirname(lane.root)+'/');
 for(const d of Object.values(book.tlds))if(d.$==='Def')for(const p of d.i??[])pinLoaded(p);
 report.loadedInputs=[...observed].sort();event('loaded','',{bookEvents:book.order.length,modules:seen.size});
 phase='validate';save();const expectedDefs=Object.values(book.tlds).filter(d=>d.$==='Def'&&d.v!==null).length;
 K.book_valid(book);if(book.hols)throw Error('Canonical validation left holes');
 let checked=0;for(const d of Object.values(book.tlds))if(d.$==='Def'&&d.v!==null){if(d.e===undefined)throw Error('Missing checked body');checked++;}
 if(checked!==expectedDefs||checked!==plan.expectedCheckedDefinitions||book.order.length!==plan.expectedBookEvents)throw Error('Full validation coverage mismatch');
 report.checkedDefinitions=checked;report.eventsFullyValidated=book.order.length;event('validated','',{checkedDefinitions:checked,bookEvents:book.order.length});
 phase='codegen';codegenStart=performance.now();save();
 const observer=createCompileBookObserver(undefined,{onEvent:event});
 const c=C.compile_book(book,{observe:observer.observe});
 report.codegenMs=performance.now()-codegenStart;phase='publish';event('compile-return','',{outputUTF16Units:c.length});
 const output=reportPath+'.c',publicationStart=performance.now();report.outputPath=output;save();
 await Bun.write(output,c);report.publicationMs=performance.now()-publicationStart;report.outputPublished=true;event('c-published','',{bytes:statSync(output).size});
 phase='output-authentication';save();const h=createHash('sha256');for await(const chunk of createReadStream(output))h.update(chunk);
 report.output={path:output,sha256:h.digest('hex'),bytes:statSync(output).size,utf16Units:c.length};
 report.expectedAcceptedC=cell.source==='R12'?{sha256:plan.acceptedC.sha256,matches:report.output.sha256===plan.acceptedC.sha256}:null;
 authenticate();report.status='COMPLETE_C_CONSTRUCTION';phase='complete';
}catch(error){report.status='FAIL';report.reason=kernel&&error?.$==='Err'?kernel.err_show(error):String(error?.stack??error);process.exitCode=2;}
finally{closeSync(fd);report.progressSha256=progressHash.digest('hex');report.structuralTraceSha256=traceHash.digest('hex');report.observerEvents=sequence;report.terminal=true;save();console.log('N11_WORKER '+JSON.stringify({caseId,status:report.status,phase:report.phase,events:sequence,output:report.output??null}));}
