#!/usr/bin/env bun
/** Authenticate the complete native workload closure for the compiler root.
 * bun --smol evals/native_seed_corpus.ts --root=PATH.bend --out=FRESH.json
 * [--expect-closure=RECORD.json]
 *
 * Trusted host import resolution only, using the native host's own POSIX
 * lexical namespace rule (see native_seed_runtime.mjs). Declared `.js`
 * alternatives are recorded as passive BIR.SourceFile byte rows. The emitted
 * manifest is exactly what native_compiler_experiment.ts pins and what the
 * native host validates before parsing. --expect-closure additionally requires
 * that this closure equals an independently recorded file->sha256 map.
 */
import {readFileSync, realpathSync, writeFileSync, existsSync} from 'node:fs';
import {resolve} from 'node:path';
import {corpusFor, hashPath, workloadRows} from './native_seed_runtime.mjs';

const options = new Map<string, string>();
for (const argument of process.argv.slice(2)) {
  const at = argument.indexOf('='), key = argument.slice(0, at), value = argument.slice(at + 1);
  if (at < 0 || !['--root', '--out', '--expect-closure'].includes(key) || !value || options.has(key))
    throw Error('Expected unique --root=PATH --out=FRESH.json [--expect-closure=RECORD.json]');
  options.set(key, value);
}
if (!options.has('--root') || !options.has('--out')) throw Error('Required --root and --out');
const root = realpathSync(options.get('--root')!);
const out = resolve(options.get('--out')!);
if (existsSync(out)) throw Error('Use a fresh corpus path: ' + out);
const rows = workloadRows(root);
const corpus = corpusFor(rows);
writeFileSync(out, JSON.stringify(corpus, null, 2) + '\n', {flag: 'wx'});

if (options.has('--expect-closure')) {
  const expected = JSON.parse(readFileSync(options.get('--expect-closure')!, 'utf8')) as Record<string, string>;
  const observed = new Map(rows.sources.map(row => [row.file, row]));
  if (Object.keys(expected).length !== observed.size) throw Error('Native closure row count differs from the recorded closure');
  for (const [path, digest] of Object.entries(expected)) {
    const row = observed.get(realpathSync(path));
    if (!row || row.sha256 !== digest) throw Error('Native closure differs from the recorded closure: ' + path);
  }
}
console.log(JSON.stringify({
  corpus: out, corpusSha256: hashPath(out), directory: rows.directory, root,
  sources: rows.sources.length, externals: rows.externals.length, files: corpus.files.length,
}));
