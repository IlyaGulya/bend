import {Worker} from 'node:worker_threads';
const worker=new Worker(new URL('./checker_core_census_worker.mjs',import.meta.url),{argv:process.argv.slice(2),resourceLimits:{stackSizeMb:256}});
worker.on('error',error=>{console.error(String(error));process.exitCode=2;});
worker.on('exit',code=>{if(code)process.exitCode=code;});
