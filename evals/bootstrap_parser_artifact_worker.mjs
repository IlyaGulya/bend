import {Worker,isMainThread,parentPort,workerData} from 'node:worker_threads';
import {createInterface} from 'node:readline';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
if(isMainThread){
 if(!process.argv[2])throw Error('Expected new parser artifact path');
 const fuel=Number(process.argv[3]??2000000);if(!Number.isSafeInteger(fuel)||fuel<0)throw Error('Invalid explicit test fuel');
 const worker=new Worker(new URL(import.meta.url),{resourceLimits:{stackSizeMb:256},workerData:{artifact:pathToFileURL(resolve(process.argv[2])).href,fuel}});
 worker.on('message',message=>console.log(message));
 worker.on('error',error=>{console.error(String(error));process.exitCode=2;});
 const lines=createInterface({input:process.stdin});for await(const line of lines)worker.postMessage(JSON.parse(line));await worker.terminate();
}else{
 const parser=(await import(workerData.artifact)).default;
 let fuel={$:'FeedbackFuelEnd'};for(let i=0;i<workerData.fuel;i++)fuel={$:'FeedbackFuelCell',tail:fuel};
 parentPort.on('message',request=>{try{
  const run=parser.parse_with_fuel(fuel,request.file,request.source);
  if(run.$!=='FeedbackComplete')throw Error('Explicit fuel result '+run.$);
  const value=run.value;
  if(!/^Value_\d+$/.test(value?.$?.split('.').at(-1)??'')||
    !['ParseSuccess','ParseFailure'].includes(value.result?.$?.split('.').at(-1)))
    throw Error('Invalid parser feedback payload '+value?.$);
  parentPort.postMessage(JSON.stringify({id:request.id,result:value.result},(_,v)=>typeof v==='bigint'?{$:'$NativeNat',value:String(v)}:v));
 }catch(error){parentPort.postMessage(JSON.stringify({id:request.id,error:String(error)}));}});
}
