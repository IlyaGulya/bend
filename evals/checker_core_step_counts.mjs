/** Observation-only --driver for compiler_benchmark.ts.
 * Counts opaque native Run chunk advances, not old request/resume boundaries.
 * Multiple checker passes use distinct write-once files.
 * Historical v46 request/callback observations remain in their frozen receipt.
 */
import {writeFileSync} from 'node:fs';
import {runCheckerSteps as driveChecker} from './checker_core_step_runtime.mjs';
export {runTemplateSteps,runEmitterSteps,runLibraryEmitterSteps,runCheckedInspectionSteps} from './checker_core_step_runtime.mjs';
const captures=new Map();
export function runCheckerSteps(component,modules){
 const base=process.env.BEND_CHECKER_COUNTS_FILE;
 if(!base)throw Error('BEND_CHECKER_COUNTS_FILE is required for diagnostic counts');
 if(typeof component?.checker_step!=='function')throw Error('Invalid checker step ABI: missing checker_step export');
 const capture=(captures.get(base)??0)+1,path=capture===1?base:base+'.pass-'+capture+'.json';
 let chunkAdvances=0;
 const result=driveChecker({...component,checker_step:run=>{chunkAdvances++;return component.checker_step(run);}},modules);
 const report={phaseTraceVersion:3,progressABI:'typed-native-stack-v57t',chunkQuantum:64,chunkAdvances,result:result.$?.split('.').at(-1),countScope:'Exact host calls to checker_step on opaque CheckerRunState; initial start chunk is not counted; native transitions and source callbacks are not observed',capture,base,path};
 writeFileSync(path,JSON.stringify(report),{flag:'wx'});
 captures.set(base,capture);
 return result;
}
