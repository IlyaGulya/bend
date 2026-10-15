import {sourceOracle} from './bootstrap_source_oracle.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {writeFileSync} from 'node:fs';
await guardHeavyGate(import.meta.path,{label:'Stage0 exact bootstrap syntax and prefix boundary oracle'});
const manifest=await Bun.file('checkpoints/bootstrap-real-source-corpus.json').json();
const candidates=await Bun.file('checkpoints/bootstrap-compiled-prefix-candidates.json').json();
const rows:any[]=[];
function compact(result:Awaited<ReturnType<typeof sourceOracle>>){return {accepted:result.accepted,boundaries:result.boundaries,imports:result.imports,exclusions:result.exclusions,failure:result.failure,error:result.error,observation:result.observation};}
for(const item of manifest.modules){
 const source=await Bun.file(item.snapshot).text();console.log(JSON.stringify({stage:'oracle',file:item.file}));
 const result=await sourceOracle(item.file,source);const row:any={file:item.file,sourceSha256:item.sourceSha256,stage0:compact(result)};
 const candidate=candidates.rows.find((r:any)=>r.file===item.file);
 if(candidate){
  row.lastPassingPrefix={end:candidate.lastPassing.end,stage0:compact(await sourceOracle(item.file,source.slice(0,candidate.lastPassing.end)))};
  row.firstFailingPrefix={end:candidate.firstFailure.end,stage0:compact(await sourceOracle(item.file,source.slice(0,candidate.firstFailure.end)))};
  row.firstFailingDeclaration=candidate.firstFailure;
  row.boundaryConfirmed=result.boundaries.some(b=>b.beg===candidate.firstFailure.beg);
 }
 rows.push(row);writeFileSync('checkpoints/bootstrap-stage0-boundaries.json',JSON.stringify({rows},null,2)+'\n');
 console.log(JSON.stringify({file:item.file,stage0Accepted:result.accepted,decls:result.boundaries.length,failure:result.failure,error:result.error,lastPrefixAccepted:row.lastPassingPrefix?.stage0.accepted,firstPrefixAccepted:row.firstFailingPrefix?.stage0.accepted,boundaryConfirmed:row.boundaryConfirmed}));
 Bun.gc(true);
}
