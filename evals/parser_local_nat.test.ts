import {test,expect} from 'bun:test';
import {mkdtempSync,rmSync} from 'node:fs';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
const layer=process.env.BOOTSTRAP_OPERATOR_LAYER??'canonical';
const directory=mkdtempSync(join(tmpdir(),'bend-local-nat-regression-'));
try{
 for(const [name,script,selection] of [
   ['local','evals/parser_local_differential.ts','--suite=locals'],
   ['template-observation','evals/parser_local_differential.ts','--suite=templates'],
   ['nat-pattern','evals/parser_nat_pattern_differential.ts','--suite=all'],
 ] as const){
   const report=join(directory,name+'.json');
   const args=['--smol',script,'--layer='+layer,selection,'--report='+report];
   if(process.env.BOOTSTRAP_PARSER_SOURCE)args.push('--parser='+process.env.BOOTSTRAP_PARSER_SOURCE);
   if(process.env.BOOTSTRAP_PARSER_ARTIFACT)args.push('--artifact='+process.env.BOOTSTRAP_PARSER_ARTIFACT);
   const child=Bun.spawnSync([process.execPath,...args],{env:{...process.env,HEAVY_GATE_MEMORY_MIB:'8192',HEAVY_GATE_RSS_MIB:'8192',HEAVY_GATE_POLL_MS:'10'},stdout:'pipe',stderr:'pipe'});
   if(child.exitCode)throw Error(new TextDecoder().decode(child.stdout)+'\n'+new TextDecoder().decode(child.stderr));
   const proof=await Bun.file(report).json();
   for(const row of proof.rows)test(name+' complete stage0 parser behavior: '+row.name,()=>{
     expect(row.error).toBeUndefined();
     expect(row.accepted).toBe(row.stage0Accepted);
     expect(row.semanticParity).toBe(true);
     if(row.accepted)expect(row.actual).toEqual(row.expected);
     if(name==='nat-pattern'&&row.accepted)expect(row.actualPatterns).toEqual(row.expectedPatterns);
   });
 }
}finally{rmSync(directory,{recursive:true,force:true});}
