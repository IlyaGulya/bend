import {createHash} from 'node:crypto';
import {existsSync,mkdirSync,readFileSync,realpathSync,writeFileSync} from 'node:fs';
import {dirname,resolve} from 'node:path';
import {fileURLToPath,pathToFileURL} from 'node:url';
const [repo,root,bridge,emission,output]=process.argv.slice(2);
if(!repo||!root||!bridge||!output||!['eager','deferred'].includes(emission))throw Error('Expected repo root bridge eager|deferred output-prefix');
const {guardHeavyGate}=await import(pathToFileURL(resolve(repo,'evals/heavy_gate.ts')).href);
await guardHeavyGate(fileURLToPath(import.meta.url),{label:'Full unprofiled C emission '+emission});
if(existsSync(output+'.c')||existsSync(output+'.json'))throw Error('Fresh output required');
mkdirSync(dirname(output),{recursive:true});
const sha=bytes=>createHash('sha256').update(bytes).digest('hex'),inputs=new Map();
const pin=p=>{p=realpathSync(p);const h=sha(readFileSync(p));if(inputs.has(p)&&inputs.get(p)!==h)throw Error('Input changed: '+p);inputs.set(p,h);};
let K,phase='imports',report={schemaVersion:1,status:'FAIL',emission,root,bridge,compilerAccepted:false,performanceAccepted:false,newFixedpointClaim:false};
const start=performance.now();
try{
 for(const p of [resolve(repo,'bend2/bend.ts'),resolve(repo,'bend2/comp.ts'),resolve(repo,'evals/heavy_gate.ts'),resolve(repo,'evals/heavy_gate_native.c'),fileURLToPath(import.meta.url)])pin(p);
 K=await import(pathToFileURL(resolve(repo,'bend2/bend.ts')).href);const C=await import(pathToFileURL(resolve(repo,'bend2/comp.ts')).href);
 const book=K.book_nil(),seen=new Map();seen.set=function(p,ns){if(ns===null)pin(p);return Map.prototype.set.call(this,p,ns);};
 const source=realpathSync(root);phase='load-root';await K.book_load(book,source,'',seen);
 // Exactly the canonical native constructor's second-root coordinate system.
 phase='load-bridge';await K.book_load(book,realpathSync(bridge),'',seen,undefined,dirname(source)+'/');
 phase='validate';const validationStart=performance.now();K.book_valid(book);if(book.hols)throw Error('Canonical validation left holes');
 let checkedDefinitions=0;for(const d of Object.values(book.tlds)){if(d.$==='Def'){if(d.v!==null){checkedDefinitions++;if(d.e===undefined)throw Error('Missing checked body');}for(const p of d.i??[])if(p.endsWith('.c'))pin(p);}}
 if(checkedDefinitions!==12456)throw Error('Full R12 source definition count changed: '+checkedDefinitions);
 const validationMs=performance.now()-validationStart;phase='codegen';const codegenStart=performance.now();
 const c=C.compile_book(book,{emission}),codegenMs=performance.now()-codegenStart;
 phase='authenticate';for(const [p,h] of inputs)if(sha(readFileSync(p))!==h)throw Error('Input changed after construction: '+p);
 phase='publish';writeFileSync(output+'.c',c,{flag:'wx'});
 report={...report,status:'UNPROFILED_FULL_C_EMITTED_NOT_NATIVE_OR_FIXEDPOINT',checkedDefinitions,checksExcluded:0,outputPatches:0,eventsFullyValidated:book.order.length,validationMs,codegenMs,cBytes:Buffer.byteLength(c),cSha256:sha(c),output:output+'.c',observerEnabled:false,runtime:{name:'bun',executable:process.execPath,sha256:sha(readFileSync(process.execPath)),versions:process.versions,platform:process.platform,arch:process.arch,ramHint:process.env.BUN_JSC_forceRAMSize??null}};
}catch(error){
 const reason=K&&error&&typeof error==='object'&&error.$==='Err'?K.err_show(error):String(error instanceof Error?error.message:error);
 report={...report,status:'FAIL',phase,reason};console.error(reason);process.exitCode=1;
}finally{
 report={...report,terminal:true,elapsedMs:performance.now()-start,inputs:[...inputs].map(([path,sha256])=>({path,sha256}))};
 writeFileSync(output+'.json',JSON.stringify(report,null,2)+'\n',{flag:'wx'});
 console.log(JSON.stringify({status:report.status,emission,phase,checkedDefinitions:report.checkedDefinitions,codegenMs:report.codegenMs,cSha256:report.cSha256,report:output+'.json'}));
}
