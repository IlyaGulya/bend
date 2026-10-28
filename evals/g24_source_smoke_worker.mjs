/** G24 changed-path source smoke: canonical emission transport.
 * Same accepted stack as the G14/G23 canonical worker (256 MiB worker stack,
 * 3072 MiB old generation, 128 MiB young generation). Imports the engine from
 * the repository; carries no language logic of its own.
 * Usage: node --experimental-strip-types evals/g24_source_smoke_worker.mjs <source.bend> <out.c|out.js>
 */
import {Worker, isMainThread, workerData} from 'node:worker_threads';
import {resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
import {writeFileSync} from 'node:fs';
if(isMainThread){
 const [source,output]=process.argv.slice(2);
 if(!source||!output)throw Error('Expected source and output paths');
 const worker=new Worker(new URL(import.meta.url),{workerData:{root:process.cwd(),source:resolve(source),output:resolve(output)},resourceLimits:{stackSizeMb:256,maxOldGenerationSizeMb:3072,maxYoungGenerationSizeMb:128}});
 worker.on('error',error=>{console.error(error);process.exitCode=1;});
 worker.on('exit',code=>{if(code!==0)process.exitCode=code;});
}else{
 let kernel;
 try{
  kernel=await import(pathToFileURL(resolve(workerData.root,'bend2/bend.ts')).href);
  const compiler=await import(pathToFileURL(resolve(workerData.root,'bend2/comp.ts')).href),book=kernel.book_nil();
  await kernel.book_load(book,workerData.source,'',new Map());kernel.book_valid(book);
  if(book.hols)throw Error('Unfilled book');
  const output=workerData.output.endsWith('.c')?compiler.compile_book(book):compiler.js_book(book);
  writeFileSync(workerData.output,output);
  console.log(JSON.stringify({status:'CANONICAL_PROGRAM_EMITTED',source:workerData.source,output:workerData.output,events:book.order.length,bytes:Buffer.byteLength(output)}));
 }catch(error){console.error(error&&typeof error==='object'&&error.$==='Err'?kernel.err_show(error):error);process.exitCode=1;}
}
