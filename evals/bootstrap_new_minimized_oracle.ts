import {sourceOracle} from './bootstrap_source_oracle.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {writeFileSync} from 'node:fs';
await guardHeavyGate(import.meta.path,{label:'Stage0 minimized bootstrap grammar oracle'});
const traces=await Bun.file('checkpoints/bootstrap-parser-newly-exposed-traces.json').json(),rows=[];
for(const fixture of traces.rows){const source='import Base\n'+fixture.source;const result=await sourceOracle('checkpoints/checker_core_driver.bend',source);if(!result.accepted)throw Error('Minimized syntax not accepted by stage0 '+fixture.name+': '+JSON.stringify(result.error));rows.push({name:fixture.name,source,stage0Accepted:true,boundaries:result.boundaries,canonicalAccepted:fixture.result==='ParseSuccess',canonicalHelper:fixture.helper,canonicalRemainder:fixture.remainder});console.log(JSON.stringify({name:fixture.name,stage0Accepted:true,canonicalAccepted:fixture.result==='ParseSuccess'}));}
writeFileSync('checkpoints/bootstrap-new-minimized-stage0-oracle.json',JSON.stringify({rows},null,2)+'\n');
