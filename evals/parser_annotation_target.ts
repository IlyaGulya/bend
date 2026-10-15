import {createHash,randomUUID} from 'node:crypto';
import {guardHeavyGate} from './heavy_gate.ts';
import {writeFileSync,rmSync} from 'node:fs';
import {resolve} from 'node:path';
await guardHeavyGate(import.meta.path,{label:'Fresh annotation native target; trusted prefix diagnostic'});
const [candidate,target,output]=process.argv.slice(2);
if(!candidate||!target||!output)throw Error('Usage: candidate target report');
const checked:string[]=[],start=performance.now();
const loaderPath=resolve('evals','.annotation_loader_'+randomUUID()+'.ts');
const loader=await Bun.file('evals/load_replay_kernel.ts').text();
const historical="'bend2/selfhost/parser.bend':'f425995af41087dfa51f79e7b04259ea5d1acfa9906061c7ed57199bad4e18df'";
if(loader.split(historical).length!==2)throw Error('Historical canonical pin anchor drift');
const canonicalPin='a16bd71391493c8363ed99e88852f331d265fbe3589508c1332a01c548153075';
if(createHash('sha256').update(await Bun.file('bend2/selfhost/parser.bend').text()).digest('hex')!==canonicalPin)throw Error('Authorized canonical source drift');
writeFileSync(loaderPath,loader.replace(historical,"'bend2/selfhost/parser.bend':'"+canonicalPin+"'"));
const {replayKernel,checkFrozen}=await import(loaderPath);
const handle=await replayKernel('direct',undefined,{retention:'retain',observeCheck:(name,stage)=>{if(stage==='before')checked.push(name);}});
try{
 const K=handle.kernel,book=K.book_nil();await K.book_load(book,resolve(candidate),'',new Map());
 const declarations=book.order.length,index=book.order.lastIndexOf(target);if(index<0)throw Error('Missing target');
 book.order=book.order.slice(0,index+1);K.book_valid(book,index);
 if(checked.length!==1||checked[0]!==target)throw Error('Unexpected checked declaration set');
 const report={status:'TARGET_PASS',diagnosticOnly:true,candidate:resolve(candidate),target,index,declarations,nativeDone:index,prefixBodiesChecked:0,checked,retainedE:book.tlds[target]?.$==='Def'&&book.tlds[target].e!=null,elapsedMs:performance.now()-start};
 writeFileSync(output,JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report));
}catch(error){const detail=(error as any)?.$==='Err'?handle.kernel.err_show(error as any):String(error);writeFileSync(output,JSON.stringify({status:'FAIL',target,checked,error:detail},null,2)+'\n');console.error(detail);process.exitCode=2;}
finally{handle.close();await checkFrozen();rmSync(loaderPath,{force:true});}
