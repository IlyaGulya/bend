import {Worker,isMainThread,parentPort,workerData} from 'node:worker_threads';
import {createInterface} from 'node:readline';
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
import {writeNativeAst} from './bootstrap_ast_transport.ts';

const sha=bytes=>createHash('sha256').update(bytes).digest('hex');
const tag=value=>value?.$?.split('.').at(-1);
const runtime={name:'node',heapLimitMiB:3072,stackSizeMiB:256,manualGC:false};
if(isMainThread){
 const artifactPath=process.argv[2],artifactSha256=process.argv[3];
 if(!artifactPath||!/^[0-9a-f]{64}$/.test(artifactSha256??''))throw Error('Explicit authenticated native parser artifact required');
 const worker=new Worker(new URL(import.meta.url),{workerData:{artifactPath:resolve(artifactPath),artifactSha256},
  resourceLimits:{stackSizeMb:256,maxOldGenerationSizeMb:3072}});
 const lines=createInterface({input:process.stdin});
 worker.on('message',message=>console.log(JSON.stringify(message)));
 worker.on('error',error=>{console.error(String(error));process.exitCode=2;lines.close();process.stdin.destroy();});
 worker.on('exit',code=>{if(code)process.exitCode=code;lines.close();process.stdin.destroy();});
 for await(const line of lines)worker.postMessage(JSON.parse(line));
 worker.postMessage({kind:'close'});
}else{
 const authenticate=()=>{if(sha(readFileSync(workerData.artifactPath))!==workerData.artifactSha256)throw Error('Native parser artifact changed during execution');};
 authenticate();
 const parser=(await import(pathToFileURL(workerData.artifactPath).href)).default;
 if(typeof parser?.parse_with_fuel!=='function')throw Error('Actual native parser parse_with_fuel ABI missing');
 // Native comp.ts reads the declared tail field, not optional transport metadata.
 let fuel={$:'FeedbackFuelEnd'};
 for(let i=0;i<2000000;i++)fuel={$:'FeedbackFuelCell',tail:fuel};
 parentPort.on('message',request=>{
  if(request.kind==='close'){parentPort.removeAllListeners('message');parentPort.close();return;}
  try{
   if(request.kind!=='parse'||typeof request.file!=='string'||typeof request.source!=='string'||typeof request.transport!=='string')throw Error('Invalid native semantic request');
   authenticate();
   const run=parser.parse_with_fuel(fuel,request.file,request.source);
   if(tag(run)!=='FeedbackComplete'||!/^Value_\d+$/.test(tag(run.value)??'')||!['ParseSuccess','ParseFailure'].includes(tag(run.value.result)))throw Error('Actual native parser feedback did not return a complete parse result');
   // The authenticated compiler result is the only AST producer. Preserve the
   // complete native graph, scalar kinds and named/positional field order.
   const receipt=writeNativeAst(request.transport,run.value.result);
   authenticate();
   parentPort.postMessage({id:request.id,transport:request.transport,transportSha256:receipt.sha256,transportBytes:receipt.bytes,
    artifactSha256:workerData.artifactSha256,sourceSha256:sha(request.source),runtime,compiledExecution:true});
  }catch(error){parentPort.postMessage({id:request.id,error:String(error),stack:error instanceof Error?error.stack:undefined});}
 });
}
