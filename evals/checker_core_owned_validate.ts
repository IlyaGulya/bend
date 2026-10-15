import {frozen} from './load_replay_kernel.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {writeFileSync,readFileSync,rmSync} from 'node:fs';
import {createHash,randomUUID} from 'node:crypto';
import {resolve} from 'node:path';
await guardHeavyGate(import.meta.path,{label:'Ownership-annotated exact CheckerCore native validation'});
const canonicalSha256='d4fbf8813d8eb940b2eadf959cfa69db7d063256c4b211f93da131084620bb60';
const loaderSource=readFileSync('evals/load_replay_kernel.ts','utf8');
if(createHash('sha256').update(loaderSource).digest('hex')!=='cc460299a5ed3ef191def337760ad8d5aa5d8f40e23b942854605f4aa0b1f343')throw Error('Accepted replay loader drift');
const anchor="'bend2/selfhost/parser.bend':'"+frozen['bend2/selfhost/parser.bend']+"'";
if(loaderSource.split(anchor).length!==2)throw Error('Accepted loader pin anchor drift');
const loaderPath=resolve('evals/.checker_core_owned_loader_'+randomUUID()+'.ts');
writeFileSync(loaderPath,loaderSource.replace(anchor,"'bend2/selfhost/parser.bend':'"+canonicalSha256+"'"));
const replay=await import(loaderPath);
const kernel=await replay.replayKernel('direct',undefined,{retention:'retain'});
const options=new Map(process.argv.slice(2).map(arg=>{const at=arg.indexOf('=');return [arg.slice(0,at),arg.slice(at+1)];}));
const report=options.get('--report')??'checkpoints/checker-core-owned-validation-v1.json';
try{
 const K=kernel.kernel,book=K.book_nil();
 const file=options.get('--file')??'checkpoints/checker_core_owned_component_v1.bend';
 await K.book_load(book,file,'',new Map());
 if(Object.keys(book.tlds).some(key=>key.startsWith('Template.')||key==='check'||key==='check_template_result'))throw Error('Template boundary leaked');
 console.log(JSON.stringify({stage:'native-validation-start',events:book.order.length,checksExcluded:0}));
 K.book_valid(book);
 if(book.hols||book.open)throw Error('Incomplete native validation');
 writeFileSync(report,JSON.stringify({status:'PASS',eventsFullyValidated:book.order.length,checksExcluded:0},null,2)+'\n');
 console.log(JSON.stringify({stage:'native-validation-pass',events:book.order.length,checksExcluded:0}));
}catch(error){
 const diagnostic=error&&typeof error==='object'&&'$'in error&&error.$==='Err'?kernel.kernel.err_show(error as Parameters<typeof kernel.kernel.err_show>[0]):String(error);
 writeFileSync(report,JSON.stringify({status:'FAIL',checksExcluded:0,diagnostic},null,2)+'\n');
 console.error(diagnostic);process.exitCode=2;
}finally{kernel.close();try{await replay.checkFrozen();}finally{rmSync(loaderPath);}}
