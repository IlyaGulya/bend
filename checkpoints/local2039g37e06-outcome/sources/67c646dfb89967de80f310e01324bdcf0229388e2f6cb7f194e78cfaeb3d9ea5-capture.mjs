import {openSync,closeSync} from 'node:fs';
import {spawn} from 'node:child_process';
const [out,err,command,...args]=process.argv.slice(2);
if(!out||!err||!command)throw Error('Expected stdout stderr command args');
const stdout=openSync(out,'wx'),stderr=openSync(err,'wx');
try{
 const child=spawn(command,args,{stdio:['ignore',stdout,stderr]});
 const result=await new Promise((done,reject)=>{child.once('error',reject);child.once('close',(code,signal)=>done({code,signal}));});
 process.exitCode=result.code??128;
}finally{closeSync(stdout);closeSync(stderr);}
