import {Worker,isMainThread,parentPort,workerData} from 'node:worker_threads';
import {createInterface} from 'node:readline';
import {pathToFileURL} from 'node:url';
if(isMainThread){
 const artifactPath=process.argv[2];
 if(!artifactPath)throw Error('Explicit current native lexer artifact required');
 const worker=new Worker(new URL(import.meta.url),{workerData:{artifactPath},
   resourceLimits:{stackSizeMb:256,maxOldGenerationSizeMb:3072}});
 worker.on('message',message=>console.log(JSON.stringify(message)));
 worker.on('error',error=>{console.error(String(error));process.exitCode=2;});
 const lines=createInterface({input:process.stdin});
 for await(const line of lines)worker.postMessage(JSON.parse(line));
 await worker.terminate();
}else{
 const producer=(await import(pathToFileURL(workerData.artifactPath).href)).default;
 parentPort.on('message',request=>{
  try{
   if(request.kind!==undefined&&request.kind!=='raw-lexer')throw Error('Unknown token producer kind');
   let xs=producer['lexer.tokens'](request.source);
   const tokens=[];
   while(xs.$==='Con'){tokens.push(xs.head);xs=xs.tail;}
   if(xs.$!=='Nil')throw Error('Bad current native token list');
   parentPort.postMessage({id:request.id,tokens});
  }catch(error){parentPort.postMessage({id:request.id,error:String(error),stack:error instanceof Error?error.stack:undefined});}
 });
}
