import parser from '/Users/ilyagulya/Projects/My/bend/checkpoints/parser-explicit-fuel-822e8460.js';
import {readFileSync} from 'node:fs';
const file=process.argv[2];
let fuel={$:'FeedbackFuelEnd'};
for(let i=0;i<200000;i++)fuel={$:'FeedbackFuelCell',tail:fuel};
try {
 let source=readFileSync(file,'utf8');
 if(process.argv[3]==='--imports-only'){
  const boundaries=['\ndef ','\ntype ','\nlaw '].map(s=>source.indexOf(s)).filter(n=>n>=0);
  if(!boundaries.length)throw Error('No exact import-prefix boundary');
  source=source.slice(0,Math.min(...boundaries)+1);
 }
 const value=parser.parse_with_fuel(fuel,file,source);
 console.log(JSON.stringify(value,(_,v)=>typeof v==='bigint'?{$:'$NativeNat',value:String(v)}:v));
} catch(error) {
 console.error(String(error));
 console.error(String(error.stack).split('\n').slice(0,8).join('\n'));
 process.exitCode=2;
}
