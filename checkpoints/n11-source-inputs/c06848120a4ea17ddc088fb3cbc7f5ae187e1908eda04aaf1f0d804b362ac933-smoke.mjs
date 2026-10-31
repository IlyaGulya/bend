// Throwaway executed smoke: shadow observer seams must preserve original C bytes.
import {readFileSync,writeFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
const [planPath,reportPath]=process.argv.slice(2),plan=JSON.parse(readFileSync(planPath,'utf8'));
const hash=p=>createHash('sha256').update(readFileSync(p)).digest('hex');
for(const x of [...plan.toolPins,...plan.lanes.R12.inputs])if(hash(x.path)!==x.sha256)throw Error('Smoke input drift: '+x.path);
if(process.versions.bun!==plan.bun.version||hash(process.execPath)!==plan.bun.sha256)throw Error('Wrong smoke producer');
const {guardHeavyGate}=await import(pathToFileURL(plan.guardSource).href);await guardHeavyGate(import.meta.path,{label:'N11 shadow seam transparency smoke'});
const dir=plan.lanes.R12.directory,K=await import(pathToFileURL(dir+'/bend2/bend.ts').href);
const original=await import(pathToFileURL(dir+'/bend2/comp-control.ts').href),instrumented=await import(pathToFileURL(dir+'/bend2/comp.ts').href);
const book=K.book_nil();await K.book_load(book,plan.smoke.source,'',new Map());K.book_valid(book);if(book.hols)throw Error('Smoke validation holes');
const a=original.compile_book(book),events=[];
const b=instrumented.compile_book(book,{observe(stage,name,state){if(/^c-(graphs|metadata|tabs|spins|segs|runtime|ids|reset)-/.test(stage))events.push({stage,name,outputUTF16Units:state.outputUTF16Units??null});}});
const same=a===b,sha=createHash('sha256').update(b).digest('hex');
const result={status:same?'PASS_EXACT_ORIGINAL_C_BYTES':'FAIL_C_BYTES_DIFFER',diagnosticOnly:true,compilerAccepted:false,source:plan.smoke.source,inputSha256:hash(plan.smoke.source),originalCompilerSha256:hash(dir+'/bend2/comp-control.ts'),shadowCompilerSha256:hash(dir+'/bend2/comp.ts'),outputBytes:Buffer.byteLength(b),outputSha256:sha,events,output:reportPath+'.c',runtime:{bun:process.versions.bun,execArgv:process.execArgv}};
writeFileSync(reportPath,JSON.stringify(result,null,2)+'\n');if(!same)throw Error('Instrumentation changed generated C');
writeFileSync(result.output,b);console.log(JSON.stringify(result));
