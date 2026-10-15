import {test,expect} from 'bun:test';
import {mkdtempSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {floatFixtures} from './parser_float_fixtures.ts';

// Same source/artifact overrides and memory guards as the operator regressions.
// Default public gate proves complete AST structure as well as binary32 bits.
// The accepted larger numeric-helper corpus remains available with layer=native.
const layer=process.env.BOOTSTRAP_FLOAT_LAYER??'canonical';
const minimalOnly=process.env.BOOTSTRAP_FLOAT_MINIMAL_ONLY==='1';
const shapeOnly=layer!=='native'&&!minimalOnly;
const dir=mkdtempSync(join(tmpdir(),'bend-float-regression-'));
const report=join(dir,'report.json');
const args=['--smol',layer==='native'?'evals/parser_float_native_gate.ts':'evals/parser_float_differential.ts','--report='+report];
if(layer!=='native')args.push('--layer='+layer);
if(process.env.BOOTSTRAP_PARSER_SOURCE)args.push('--parser='+process.env.BOOTSTRAP_PARSER_SOURCE);
if(process.env.BOOTSTRAP_PARSER_ARTIFACT)args.push('--artifact='+process.env.BOOTSTRAP_PARSER_ARTIFACT);
if(minimalOnly)args.push('--minimal-only');
if(shapeOnly)args.push('--shape-only');
function record(value: unknown): Record<string,unknown> {
  if(!value || typeof value!=='object' || Array.isArray(value))throw Error('Invalid float regression report object');
  return value as Record<string,unknown>;
}
function records(value: unknown): Record<string,unknown>[] {
  if(!Array.isArray(value))throw Error('Invalid float regression report rows');
  return value.map(record);
}
let evidence: Record<string,unknown>;
try {
  const run=Bun.spawnSync([process.execPath,...args],{
    env:{...process.env,HEAVY_GATE_MEMORY_MIB:'8192',HEAVY_GATE_RSS_MIB:'8192',HEAVY_GATE_POLL_MS:'10'},
    stdout:'pipe',stderr:'pipe',
  });
  if(run.exitCode)throw Error(new TextDecoder().decode(run.stdout)+'\n'+new TextDecoder().decode(run.stderr));
  const payload: unknown=await Bun.file(report).json();
  evidence=record(payload);
} finally {
  rmSync(dir,{recursive:true,force:true});
}
const rows=records(evidence.rows);
const selected=minimalOnly?floatFixtures.slice(0,1):shapeOnly
  ? ['3.14159265','3.14','0.5','0.0','1.00000006'].map(literal=>floatFixtures.find(row=>row.literal===literal)!)
  : floatFixtures;
for(const [index,fixture] of selected.entries())test('F32 AST and bits match stage0: '+fixture.literal,()=>{
  const row=rows[index];
  expect(row.stage0Accepted).toBe(true);
  expect(layer==='native'?row.nativeAccepted:row.accepted).toBe(true);
  expect(row.expectedBits).toMatch(/^0x[0-9a-f]{8}$/);
  expect(row.actualBits).toBe(row.expectedBits);
  if(fixture.pinnedBits) {
    expect(row.expectedBits).toBe(fixture.pinnedBits);
    expect(row.actualBits).toBe(fixture.pinnedBits);
  }
  expect(row.bitParity).toBe(true);
  if(layer!=='native') {
    expect(row.semanticParity).toBe(true);
    expect(row.actual).toEqual(row.expected);
  }
  expect(row.error).toBeUndefined();
});
