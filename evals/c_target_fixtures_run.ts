/**
 * Compile the C-target fixture programs with a built self-host driver and run
 * the emitted executables. Each fixture carries `#|<number>` as the expected
 * stdout, so this is the end-to-end shape: parse, check, lower to BIR, emit C
 * through c_backend, clang, run.
 *
 * Usage: bun evals/c_target_fixtures_run.ts --driver=<path to bend2 driver> [--keep]
 */
import {readFileSync, writeFileSync} from 'node:fs';
import {basename, resolve} from 'node:path';

const driver = process.argv.find(arg => arg.startsWith('--driver='))?.slice('--driver='.length);
if (!driver) throw Error('usage: --driver=<built bend2 driver>');
const keep = process.argv.includes('--keep');
const base = resolve('bend2/base.bend');
const runtime = resolve('bend2/selfhost/c_runtime.c');
const fixtures = ['evals/c_target_wide_record', 'evals/c_target_nested_adt',
  'evals/c_target_array_u32', 'evals/c_target_array_wide', 'evals/c_target_multiarm',
  'evals/c_target_char_head', 'evals/c_target_char_to_list', 'evals/c_target_string_from_list',
  'evals/c_target_array_nat', 'evals/c_target_array_nested', 'evals/c_target_drop_fields',
  'tests/reg/phys_storage_paths'];

for (const name of fixtures) {
  const source = resolve(name + '.bend');
  const expected = [...readFileSync(source, 'utf8').matchAll(/^#\|(.+)$/gm)].map(match => match[1]).join('\n');
  if (expected.length === 0) throw Error(name + ': no #| expectation');
  const stem = basename(name);
  const c = '/tmp/' + stem + '.c';
  const exe = '/tmp/' + stem;
  const compile = Bun.spawnSync([driver, source, '-o', c, '--base', base, '--runtime-c', runtime],
    {stdout: 'pipe', stderr: 'pipe'});
  if (compile.exitCode !== 0) {
    console.error(new TextDecoder().decode(compile.stdout).slice(0, 30), new TextDecoder().decode(compile.stderr).slice(0, 4000));
    throw Error(name + ': driver exited ' + compile.exitCode);
  }
  const cc = Bun.spawnSync(['clang', '-std=c11', '-O0', '-o', exe, c], {stdout: 'pipe', stderr: 'pipe'});
  if (cc.exitCode !== 0) {
    console.error(new TextDecoder().decode(cc.stderr).slice(0, 4000));
    throw Error(name + ': clang failed');
  }
  const run = Bun.spawnSync([exe], {stdout: 'pipe', stderr: 'pipe'});
  const out = new TextDecoder().decode(run.stdout).trim();
  if (run.exitCode !== 0) {
    console.error(new TextDecoder().decode(run.stderr).slice(0, 2000));
    throw Error(name + ': run exited ' + run.exitCode);
  }
  if (out !== expected) throw Error(name + ': observed ' + out + ', expected ' + expected);
  if (!keep) { try { Bun.spawnSync(['rm', '-f', c, exe]); } catch { /* temp files */ } }
  console.log(JSON.stringify({fixture: basename(source), observed: out}));
}
console.log(JSON.stringify({status: 'PASS', fixtures: fixtures.length}));
