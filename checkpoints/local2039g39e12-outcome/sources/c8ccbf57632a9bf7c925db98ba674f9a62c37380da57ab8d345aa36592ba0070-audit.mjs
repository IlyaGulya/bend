import assert from 'node:assert/strict';
import {once,sha} from './auth.mjs';
const KEY='__e12SourceAudit';
let phases=[];
export function instrument(source){
 assert.ok(!globalThis[KEY],'fresh worker required');
 const counters={normal:0,caught:0,nestedNormal:0,nestedCaught:0,retiredSlots:0,maxWrittenEnd:0,maxPreservedPrefix:0};
 globalThis[KEY]={counters,read:null,before(hi,base,caught){counters[caught?'caught':'normal']++;if(base>0)counters[caught?'nestedCaught':'nestedNormal']++;counters.retiredSlots+=Math.max(0,hi-base);counters.maxWrittenEnd=Math.max(counters.maxWrittenEnd,hi);counters.maxPreservedPrefix=Math.max(counters.maxPreservedPrefix,base);},after(before,after){assert.equal(after,before,'cleanup changed argument length');}};
 const lines=source.match(/^function run_base\(x,k0,s0\) \{[^\n]*$/gm);assert.equal(lines?.length,1);let line=lines[0];
 for(const [anchor,caught]of [['if ($ksp===k0) { $sp=s0;',false],['$ksp=k0; $sp=s0;',true]]){
  const original=anchor+' if($stHi>s0){$stArgs.fill(undefined,s0,$stHi);$stHi=s0;}';
  const observed=anchor+' const $e12Length=$stArgs.length; globalThis.'+KEY+'.before($stHi,s0,'+caught+'); if($stHi>s0){$stArgs.fill(undefined,s0,$stHi);$stHi=s0;} globalThis.'+KEY+'.after($e12Length,$stArgs.length);';
  line=once(line,original,observed);
 }
 const result=once(source,lines[0],line)+`\nglobalThis.${KEY}.read=()=>{let nonnull=0,nonnullSuffix=0;for(let i=0;i<$stArgs.length;i++)if($stArgs[i]!==undefined){nonnull++;if(i>=$sp)nonnullSuffix++;}return {sp:$sp,ksp:$ksp,hi:$stHi,argumentLength:$stArgs.length,nonnull,nonnullSuffix};};\n`;
 return {source:result,metadata:{originalSha256:sha(source),outputSha256:sha(result),passive:true,cleanupTransformed:false,scalarOnly:true,scope:'Existing owned-prefix cleanup observed, no owners retained; complete quiescent argument-slot scan only, not other roots or retained bytes'}};
}
export function onPhase(phase){const state=globalThis[KEY]?.read?.();if(state)phases.push({phase,...state});}
export function snapshot(){return {counters:globalThis[KEY]?.counters??null,boundaries:phases,current:globalThis[KEY]?.read?.()??null};}
export function requireQuiescent(){const s=snapshot().current;assert.ok(s);assert.equal(s.sp,0);assert.equal(s.ksp,0);assert.equal(s.nonnullSuffix,0,'retired argument suffix retains roots');return s;}
