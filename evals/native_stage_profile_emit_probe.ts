#!/usr/bin/env node
// Public diagnostic: run the profile fixture's real canonical BIR program through
// the generated Emit and print the typed EmitSuccess/EmitFailure message.
// Usage: node --stack-size=65536 --experimental-strip-types \
//   evals/native_stage_profile_emit_probe.ts
// The 64 MiB JS stack is only for js_lib code generation and is within the
// approved 256 MiB source cap; no native worker or guard limit is changed.
import {createHash} from 'node:crypto';
import {readFileSync, writeFileSync} from 'node:fs';
import {dirname, join, resolve} from 'node:path';
import {fileURLToPath, pathToFileURL} from 'node:url';
import {book_nil, book_load, book_valid} from '../bend2/bend.ts';
import {js_lib} from '../bend2/comp.ts';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const source = join(root, 'evals/native_stage_profile_emit_probe.bend');
const artifact = '/tmp/native-stage-profile-emit-probe.mjs';
const sha = (path: string) => createHash('sha256').update(readFileSync(path)).digest('hex');

const book = book_nil();
await book_load(book, source, '', new Map());
book_valid(book);
const code = js_lib(book, true, {roots: ['emit_start', 'emit_step', 'emit_message'],
  exports: ['emit_start', 'emit_step', 'emit_message']});
writeFileSync(artifact, code);
const mod = (await import(pathToFileURL(artifact).href)).default as any;
const tag = (value: any): string => String(value?.$ ?? '');
let run = mod.emit_start();
let steps = 0;
while (!tag(run).endsWith('EmitterRunFinished')) {
  if (steps >= 1_000_000) throw Error('emit probe did not finish after 1000000 chunks');
  run = mod.emit_step(run);
  steps += 1;
}
const result = mod.emit_message(run);
const status = result === 'EMIT_SUCCESS' ? 'EMIT_SUCCESS' : 'EMIT_FAILURE';
console.log(JSON.stringify({status, message: status === 'EMIT_SUCCESS' ? null : result,
  steps, source, sourceSha256: sha(source), artifact, artifactSha256: sha(artifact),
  jsStackBytes: 64 * 1024 * 1024, nativeCapsChanged: false}));
if (status !== 'EMIT_SUCCESS') process.exitCode = 1;
