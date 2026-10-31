import assert from 'node:assert/strict';
import {readFileSync,writeFileSync,mkdirSync,existsSync} from 'node:fs';
import {resolve,dirname} from 'node:path';
import {fileURLToPath} from 'node:url';
import {runHeavyGate} from '/Users/ilyagulya/Projects/My/bend/evals/heavy_gate.ts';
import {ROOT,NODE,LIMITS,json,hashPath,sha,authenticate} from './authority.mjs';
const here=dirname(fileURLToPath(import.meta.url)),[suitePath,outArg]=process.argv.slice(2),out=resolve(outArg);assert.ok(!existsSync(out),'fresh suite directory required');mkdirSync(out,{recursive:true});
const suite=json(suitePath),reportPath=out+'/receipt.json',save=()=>writeFileSync(reportPath,JSON.stringify(report,null,2)+'\n');
const capture='/private/tmp/bend-e01-e13-jbsb4I/reuse-preflight/capture.mjs',worker=here+'/source-worker.mjs';
const report={schemaVersion:1,status:'RUNNING',diagnosticOnly:true,compilerAccepted:false,performanceAccepted:false,newFixedpointClaim:false,suite:{path:resolve(suitePath),sha256:hashPath(suitePath)},authority:authenticate().proof,limits:LIMITS,commands:[],rows:[]};save();
let sequence=0;
async function run(label,command){
 const stem=out+'/'+String(sequence++).padStart(3,'0')+'-'+label,stdout=stem+'.stdout',stderr=stem+'.stderr';
 const guarded=[NODE,capture,stdout,stderr,...command],guardian=await runHeavyGate(guarded,{...LIMITS,label:'N01-N08 '+label});
 const row={label,command,stdout,stderr,stdoutSha256:existsSync(stdout)?hashPath(stdout):null,stderrSha256:existsSync(stderr)?hashPath(stderr):null,guardian};report.commands.push(row);save();assert.equal(guardian.status,'PASS','guard '+label);return row;
}
try{
 for(const test of suite.rows){
  for(const target of test.targets??['c','js']){
   const name=test.name+'-'+target,output=out+'/'+name+'.'+target,compiled=out+'/'+name+'.compile.json',request=out+'/'+name+'.request.json';
   const q={source:resolve(test.source),target,output,report:compiled,plugins:test.plugins??[],pins:{[worker]:hashPath(worker),[here+'/authority.mjs']:hashPath(here+'/authority.mjs'),[capture]:hashPath(capture)},...(test.exports?{exports:test.exports}:{}),...(test.expectedError!==undefined?{expectedError:test.expectedError}:{}),...(test.expectedCheckError!==undefined?{expectedCheckError:test.expectedCheckError}:{})};
   writeFileSync(request,JSON.stringify(q,null,2)+'\n',{flag:'wx'});
   const row={name,target,source:{path:q.source,sha256:hashPath(q.source)},expected:test.expected,status:'RUNNING'};report.rows.push(row);save();
   await run(name+'-emit',[NODE,'--experimental-strip-types','--max-old-space-size=6144','--max-semi-space-size=128',worker,request]);row.compilation={path:compiled,sha256:hashPath(compiled),data:json(compiled)};assert.equal(row.compilation.data.status,'PASS');
   if(test.expectedError!==undefined||test.expectedCheckError!==undefined){row.status='EXPECTED_REJECTION';save();continue;}
   if(target==='c'){
    const binary=out+'/'+name;await run(name+'-clang',['/usr/bin/clang','-std=c11','-O1','-pthread',output,'-lm','-o',binary]);row.binary={path:binary,sha256:hashPath(binary)};row.execution=await run(name+'-exec',[binary,...(test.args??[])]);
   }else row.execution=await run(name+'-exec',[NODE,test.caller??output,...(test.caller?[output]:[]),...(test.args??[])]);
   row.actual=readFileSync(row.execution.stdout,'utf8');assert.equal(row.actual,test.expected,'executed output '+name);assert.equal(readFileSync(row.execution.stderr,'utf8'),'','stderr '+name);row.status='PASS';save();
  }
 }
 report.status='PASS';
}catch(error){report.status='FAIL';report.error=String(error);report.stack=error?.stack;process.exitCode=1;}
save();console.log(JSON.stringify({status:report.status,report:reportPath,rows:report.rows.map(r=>({name:r.name,status:r.status,actual:r.actual})),error:report.error}));
