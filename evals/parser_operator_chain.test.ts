import {test,expect} from 'bun:test';
import {mkdtempSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
const dir=mkdtempSync(join(tmpdir(),'bend-operator-regression-')),report=join(dir,'report.json');
const layer=process.env.BOOTSTRAP_OPERATOR_LAYER??'canonical';
const args=['--smol','evals/parser_operator_differential.ts','--layer='+layer,'--report='+report];
if(process.env.BOOTSTRAP_PARSER_SOURCE)args.push('--parser='+process.env.BOOTSTRAP_PARSER_SOURCE);
if(process.env.BOOTSTRAP_PARSER_ARTIFACT)args.push('--artifact='+process.env.BOOTSTRAP_PARSER_ARTIFACT);
const run=Bun.spawnSync([process.execPath,...args],{env:{...process.env,HEAVY_GATE_MEMORY_MIB:'8192',HEAVY_GATE_RSS_MIB:'8192',HEAVY_GATE_POLL_MS:'10'},stdout:'pipe',stderr:'pipe'});
if(run.exitCode)throw Error(new TextDecoder().decode(run.stderr));
const evidence=await Bun.file(report).json();rmSync(dir,{recursive:true,force:true});
for(const row of evidence.rows)test('operator AST matches stage0: '+row.expression,()=>{
 expect(row.stage0Accepted).toBe(true);
 expect(row.accepted).toBe(true);
 expect(row.actual).toEqual(row.expected);
});
