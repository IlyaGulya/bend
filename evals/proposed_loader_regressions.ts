#!/usr/bin/env bun
/** Proposal evidence only: never modifies production kernel or changes checks. */
import * as Original from '../bend2/bend.ts';
import * as Comp from '../bend2/comp.ts';
import {replayKernel,checkFrozen} from './load_replay_kernel.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {mkdtempSync,writeFileSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {createHash} from 'node:crypto';
await guardHeavyGate(import.meta.path,{label:'Proposed direct loader positive/negative actual native check and compiled JS regressions'});
const dir=mkdtempSync(join(tmpdir(),'bend-loader-regressions-'));
const fixtures=[
 {name:'priority',value:1233n,source:`import Base

type ProbeMarker is Data:
  ProbeMark{kind: Bool, text: String}

def choose(marker: ProbeMarker) -> Nat:
  match marker:
    case ProbeMark{True{}, "+"}:
      11n
    case ProbeMark{_, "+"}:
      12n
    case _:
      13n

def main() -> Nat:
  choose(ProbeMark{True{}, "+"}) * 100n + choose(ProbeMark{False{}, "+"}) * 10n + choose(ProbeMark{False{}, "other"})
`},
 {name:'type-rejection',error:'expected',source:`import Base

def main() -> Nat:
  True{}
`},
 {name:'decrease-rejection',error:'decreasing self-call',source:`import Base

type ProbeMode is Data:
  ProbeIdle{}
  ProbeNext{}

def invalid(mode: ProbeMode, +tokens: List<&2, Nat>) -> Nat:
  match mode tokens:
    case ProbeIdle{} value <> rest:
      invalid(ProbeNext{}, rest)
    case _ _:
      0n

def main() -> Nat:
  invalid(ProbeIdle{}, [1n])
`}
];
const handle=await replayKernel('direct',undefined,{retention:'retain'});
const results:object[]=[];
try{
 for(const fixture of fixtures){
  const outcomes=[];
  for(const [label,K] of [['ordinary',Original],['proposed-direct',handle.kernel]] as const){
   const file=join(dir,fixture.name+'.bend');writeFileSync(file,fixture.source);const book=K.book_nil();let stage='load';
   try{
    await K.book_load(book,file,'',new Map());stage='full-validation';K.book_valid(book);stage='codegen';
    const code=Comp.js_lib(book,['main'],['main']),js=join(dir,fixture.name+'-'+label+'.js');writeFileSync(js,code);stage='execution';
    const child=Bun.spawn([process.execPath,'-e','import('+JSON.stringify(js)+').then(m=>console.log(String(m.default.main())))'],{stdout:'pipe',stderr:'pipe'});
    const value=(await new Response(child.stdout).text()).trim(),stderr=await new Response(child.stderr).text(),exit=await child.exited;
    if(exit!==0||!('value'in fixture)||value!==String(fixture.value))throw Error('Unexpected compiled output '+value+'; exit='+exit+'; stderr='+stderr);
    outcomes.push({toolchain:label,status:'PASS',stage,value:String(value),artifactSha256:createHash('sha256').update(code).digest('hex'),eventsFullyValidated:book.order.length});
   }catch(error){
    const detail=error&&typeof error==='object'&&'$'in error&&error.$==='Err'?K.err_show(error as Parameters<typeof K.err_show>[0]):String(error);
    if(!('error'in fixture)||!detail.includes(fixture.error)||!['load','full-validation'].includes(stage))throw Error(fixture.name+' '+label+' unexpected '+stage+': '+detail);
    outcomes.push({toolchain:label,status:'EXPECTED_REJECTION',stage,error:detail});
   }
  }
  results.push({name:fixture.name,source:fixture.source,outcomes});
 }
 const report={status:'PASS',scope:'Positive branch priority compiled execution and negative type/decrease rejection on tiny real modules only; not full parser acceptance or permission to patch kernel',kernelProposal:{file:'bend2/bend.ts',old:'  def.v = term_higher(term_lower(term_higher(body_flatten(b, vars, () => p.sc.frs++))));',replacement:'  def.v = term_higher(body_flatten(b, vars, () => p.sc.frs++));',productionModified:false,checkedOutputRetention:'native e'},results};
 writeFileSync('checkpoints/proposed-loader-regressions.json',JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report));
}finally{handle.close();rmSync(dir,{recursive:true,force:true});await checkFrozen();}
