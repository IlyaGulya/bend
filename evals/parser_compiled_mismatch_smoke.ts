import {guardHeavyGate} from './heavy_gate.ts';
import {sourceOracle} from './bootstrap_source_oracle.ts';
import {createInterface} from 'node:readline';
import {Readable} from 'node:stream';
import {writeFileSync} from 'node:fs';
import {resolve} from 'node:path';
await guardHeavyGate(import.meta.path,{label:'Minimizing first compiled parser disagreement'});
const artifact=resolve('checkpoints/bootstrap-parser-rebuild-annotation-v1.js');
const worker=Bun.spawn(['node','evals/bootstrap_parser_artifact_worker.mjs',artifact],{stdin:'pipe',stdout:'pipe',stderr:'inherit'});
const lines=createInterface({input:Readable.fromWeb(worker.stdout as any)}),iterator=lines[Symbol.asyncIterator]();
const expressions=['x * 1n + y','x * 1n','x + 1n * y','x + 1n + y','(x * 1n) + y'];
const rows:any[]=[];
try{for(const [id,expression] of expressions.entries()){
 const source=`def f(x: Nat, y: Nat) -> Nat:\n  ${expression}\n`;
 const file=resolve('checkpoints/parser-compiled-mismatch-v2-'+id+'.bend');writeFileSync(file,source);
 const oracle=await sourceOracle(file,source);
 worker.stdin.write(JSON.stringify({id,file,source})+'\n');await worker.stdin.flush();
 const reply=await iterator.next();if(reply.done)throw Error('Worker ended');
 const result=JSON.parse(reply.value);const row={id,source,stage0Accepted:oracle.accepted,result:result.error??result.result};rows.push(row);console.log(JSON.stringify(row));
 }
 writeFileSync('checkpoints/parser-compiled-first-mismatch-v2.json',JSON.stringify({artifact,origin:'Frozen parser module failure at byte 73673, line 1099',rows},null,2)+'\n');
}finally{lines.close();worker.stdin.end();await worker.exited;}
