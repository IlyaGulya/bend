import {Worker,isMainThread,parentPort} from 'node:worker_threads';
import {createInterface} from 'node:readline';
if(isMainThread){
 const worker=new Worker(new URL(import.meta.url),{resourceLimits:{stackSizeMb:256}});
 worker.on('message',message=>console.log(JSON.stringify(message,(_,v)=>typeof v==='bigint'?{$:'$NativeNat',value:String(v)}:v)));
 worker.on('error',error=>{console.error(String(error));process.exitCode=2;});
 const lines=createInterface({input:process.stdin});
 for await(const line of lines)worker.postMessage(JSON.parse(line));
 await worker.terminate();
}else{
 const parser=(await import('../checkpoints/parser-explicit-fuel-822e8460.js')).default;
 let fuel={$:'FeedbackFuelEnd'};for(let i=0;i<200000;i++)fuel={$:'FeedbackFuelCell',tail:fuel};
 parentPort.on('message',request=>{
  try{
   const run=parser.parse_with_fuel(fuel,request.file,request.source);
   if(run.$!=='FeedbackComplete')throw Error('Explicit fuel result '+run.$);
   const payload=Object.entries(run.value).find(([key])=>key!=='$')[1];
   parentPort.postMessage({id:request.id,payload});
  }catch(error){parentPort.postMessage({id:request.id,error:String(error)});}
 });
}
