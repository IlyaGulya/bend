// Bound the candidate consumer's V8 stack for large typed-step images.
// The exact same host is executed by the CLI and by the matrix driver; only
// the worker's stack/generation limits differ from an unconstrained run.
import {Worker} from 'node:worker_threads';
import {pathToFileURL} from 'node:url';

const [script, ...argv] = process.argv.slice(2);
if (!script) throw Error('Expected consumer script');

const worker = new Worker(pathToFileURL(script), {
  argv,
  resourceLimits: {stackSizeMb: 256, maxOldGenerationSizeMb: 3072},
});
worker.on('error', error => {
  console.error(error);
  process.exitCode = 1;
});
worker.on('exit', code => {
  if (code !== 0) process.exitCode = code;
});
