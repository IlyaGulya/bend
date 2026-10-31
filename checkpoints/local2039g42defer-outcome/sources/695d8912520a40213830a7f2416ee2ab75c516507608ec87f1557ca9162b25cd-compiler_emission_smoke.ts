#!/usr/bin/env bun
/**
 * Parent-run diagnostic, NOT acceptance or a timing experiment:
 *   bun evals/compiler_emission_smoke.ts --output=ABSENT_DIRECTORY
 * Run under the standard exclusive heavy gate (8192 MiB RSS AND footprint,
 * 10 ms sampling, 600000 ms deadline). It runs real C and JS consumers.
 *
 * Each checked fixture compares eager/deferred C byte-for-byte and compares
 * pass-end facts. Deferred rendering must begin with frozen IDs and no emitted
 * statement strings. Repeated C/JS calls and failed compilation must preserve
 * checked bodies and deterministic output. The generated collision fixture
 * exercises actual punctuation-to-underscore ID suffix allocation.
 *
 * Full R12 construction is separate: compiler_codegen_probe.ts --root=ROOT
 * --bridge=BRIDGE --passes=64 --max-codegen-ms=600000 --emission=eager|deferred
 * --report=NEW_JSON --output=NEW_C (one guarded process per mode), then cmp.
 * Freeze both transitive input manifests plus the root, bridge and compiler
 * source. Compare eager against the pre-change compiler as well. Statement
 * recipes do not remove expression strings or necessary facts work; their
 * allocation/memory tradeoff and full-root speed require actual measurement.
 */
import {createHash} from 'node:crypto';
import {mkdirSync, readFileSync, realpathSync, writeFileSync} from 'node:fs';
import {dirname, join, resolve} from 'node:path';
import {hostname} from 'node:os';
import {fileURLToPath} from 'node:url';
import {spawnSync} from 'node:child_process';
import * as B from '../bend2/bend.ts';
import * as C from '../bend2/comp.ts';
import {guardHeavyGate} from './heavy_gate.ts';

await guardHeavyGate(fileURLToPath(import.meta.url), {label: 'C emission separation consumer smoke'});
const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
if (process.argv.length !== 3 || !process.argv[2].startsWith('--output=') || !process.argv[2].slice(9))
  throw Error('Expected --output=ABSENT_DIRECTORY');
const output = resolve(process.argv[2].slice(9));
mkdirSync(output);
const inputs: Record<string, string> = {};
const sha = (bytes: string | Uint8Array) => createHash('sha256').update(bytes).digest('hex');
function pin(path: string): void {
  const real = realpathSync(path), digest = sha(readFileSync(real));
  if (inputs[real] !== undefined && inputs[real] !== digest) throw Error('Input changed: ' + real);
  inputs[real] = digest;
}
for (const path of ['bend2/bend.ts', 'bend2/comp.ts', 'evals/compiler_emission_smoke.ts',
  'evals/heavy_gate.ts', 'evals/heavy_gate_native.c']) pin(join(root, path));
pin(process.execPath);
function need(condition: unknown, message: string): asserts condition {
  if (!condition) throw Error(message);
}
const commands: object[] = [];
function run(command: string, args: string[]): string {
  const result = spawnSync(command, args, {cwd: root, encoding: 'utf8', timeout: 180000,
    maxBuffer: 16 * 1024 * 1024, env: {...process.env, LC_ALL: 'C'}});
  commands.push({command, args, status: result.status, signal: result.signal,
    stdout: result.stdout, stderr: result.stderr, error: result.error?.message});
  need(!result.error && result.status === 0, command + ' failed: ' + (result.error ?? result.stderr));
  return result.stdout.trim();
}
function diagnostic(error: unknown): string {
  return error && typeof error === 'object' && '$' in error && error.$ === 'Err'
    ? B.err_show(error as B.Err) : String(error);
}
async function load(source: string): Promise<B.Book> {
  const book = B.book_nil();
  class Inputs extends Map<string, string | null> {
    override set(path: string, namespace: string | null) {
      if (namespace === null) pin(path);
      return super.set(path, namespace);
    }
  }
  await B.book_load(book, source, '', new Inputs());
  for (const def of Object.values(book.tlds))
    if (def.$ === 'Def') for (const path of def.i ?? []) pin(path);
  B.book_valid(book);
  need(!book.hols, 'Validation left holes: ' + source);
  for (const def of Object.values(book.tlds))
    if (def.$ === 'Def' && def.v !== null) need(def.e !== undefined, 'Missing checked body');
  return book;
}
function checked(book: B.Book) {
  return Object.values(book.tlds).filter((d): d is B.Def => d.$ === 'Def').map(d => d.e);
}
const facts = ['ownFacts', 'hotFacts', 'staticFacts', 'lendFacts', 'literalFacts',
  'tableFacts', 'imageWords', 'spinNames', 'closerFacts'] as const;
function compile(book: B.Book, emission: 'eager' | 'deferred') {
  const passes: object[] = [];
  let rendered = false;
  const c = C.compile_book(book, {emission, observe(stage, _name, state) {
    if (/^c-pass-\d+-after$/.test(stage))
      passes.push(Object.fromEntries(facts.map(key => [key, state[key]])));
    if (emission === 'deferred' && /^c-pass-\d+-(before|after)$/.test(stage))
      need(state.segmentUTF16Units === 0, 'Deferred pass materialized statement text');
    if (stage === 'c-render-before') {
      need(state.idsFrozen && (state.statementRecipes ?? 0) > 0, 'Missing frozen emission plan');
      rendered = true;
    }
  }});
  need(emission === 'eager' || rendered, 'Deferred rendering was not reached');
  return {c, passes};
}
const collision = join(output, 'collision.bend');
writeFileSync(collision, `import Base

def a.b(x: U32) -> U32:
  (x + 1 : U32)

def a_b(x: U32) -> U32:
  (x + 2 : U32)

def check.ids(value: U32) -> IO(U32):
  import "./collision.c"
  import "./collision.js"

def main() -> IO(Unit):
  do IO<Unit>:
    value : U32 <- check.ids((a.b(10) + a_b(20) : U32))
    IO.print(U32.show(value))

#|33
`, {flag: 'wx'});
// Foreign FID references keep both entries live even if direct calls inline.
writeFileSync(join(output, 'collision.c'), `
static Term collision_run(Env e, Term* f, IoWork* w) {
  if (FID(a.b) == FID(a_b)) err_fail("colliding function IDs");
  return f[0];
}
static void __attribute__((constructor)) collision_use(void) {
  io_eff(CID(check.ids), collision_run);
}
`, {flag: 'wx'});
writeFileSync(join(output, 'collision.js'), 'io_eff(CID(check.ids), value => value);\n', {flag: 'wx'});
const fixtures = [
  'tests/compile/ctor_name_collision.bend',
  'tests/compile/ctor_dedup_grow.bend',
  'tests/reg/closure_capture_once.bend',
  'tests/reg/closure_keep_generic.bend',
  'tests/reg/closure_value_owns.bend',
  'tests/reg/brw_closure_capture.bend',
  'tests/reg/borrow_two_readers.bend',
  'tests/reg/borrow_nested_call.bend',
  'tests/reg/borrow_field_request.bend',
  'tests/reg/borrow_spin_sink.bend',
  'tests/reg/borrow_fork_hold.bend',
  'tests/reg/static_shared_cell.bend',
  'tests/reg/static_lent_literal.bend',
  'tests/reg/spin_refs_dead_seg.bend',
  'tests/reg/spin_array_hold.bend',
  'tests/import/hyphen_dir.bend',
].map(path => join(root, path)).concat(collision);
const cases: object[] = [];
const report: Record<string, unknown> = {schemaVersion: 1, diagnosticOnly: true, acceptanceEvidence: false,
  status: 'IN_PROGRESS', host: {hostname: hostname(), platform: process.platform, arch: process.arch},
  runtime: {execPath: process.execPath, versions: process.versions,
    automaticGcRamHint: process.env.BUN_JSC_forceRAMSize ?? null}, inputs, commands, cases};
try {
  const selectedCC = Bun.which(process.env.CC ?? 'cc');
  need(selectedCC, 'C compiler not found');
  const cc = realpathSync(selectedCC);
  pin(cc);
  report.cc = {path: cc, sha256: inputs[cc], version: run(cc, ['--version'])};
  for (const [index, source] of fixtures.entries()) {
    const book = await load(source), before = checked(book);
    const expected = readFileSync(source, 'utf8').split(/\r?\n/).filter(l => l.startsWith('#|'))
      .map(l => l.slice(2).trimStart()).join('\n');
    need(expected.length > 0, 'Fixture has no output oracle: ' + source);
    const eager = compile(book, 'eager'), deferred = compile(book, 'deferred');
    need(eager.c === deferred.c, 'Exact C differs: ' + source);
    need(JSON.stringify(eager.passes) === JSON.stringify(deferred.passes), 'Facts differ: ' + source);
    const js = C.js_book(book);
    need(C.compile_book(book) === eager.c, 'Default/repeated C differs: ' + source);
    need(C.js_book(book) === js, 'Repeated JS differs: ' + source);
    need(checked(book).every((body, i) => body === before[i]), 'Checked bodies changed: ' + source);
    if (source === collision) {
      need(/FID_a_b\b/.test(eager.c) && /FID_a_b_1\b/.test(eager.c), 'Collision suffix was not exercised');
      const marker = new Error('deliberate observer interruption');
      let caught: unknown;
      try { C.compile_book(book, {emission: 'deferred', observe(stage) {
        if (stage === 'c-render-before') throw marker;
      }}); } catch (error) { caught = error; }
      need(caught === marker && C.PROBES.length === 1, 'Failed render retained compiler state');
      need(C.compile_book(book, {emission: 'deferred'}) === eager.c, 'Render failure contaminated recovery');
      need(checked(book).every((body, i) => body === before[i]), 'Failed render changed checked bodies');
    }
    const stem = join(output, String(index));
    writeFileSync(stem + '.c', deferred.c, {flag: 'wx'});
    writeFileSync(stem + '.js', js, {flag: 'wx'});
    run(cc, ['-std=c11', '-O1', stem + '.c', '-lpthread', '-lm', '-o', stem]);
    const cOutput = run(stem, ['+RTS', '--threads', '1', '--gpu', 'off', '-RTS']);
    const jsOutput = run(process.execPath, [stem + '.js']);
    need(cOutput === expected && jsOutput === expected, 'Consumer output differs: ' + source);
    cases.push({source, cSha256: sha(deferred.c), jsSha256: sha(js),
      executableSha256: sha(readFileSync(stem)),
      cBytes: Buffer.byteLength(deferred.c), passes: deferred.passes, output: expected,
      exactC: true, exactFacts: true, consumers: ['C', 'JS']});
  }
  const failureSource = join(root, 'tests/reg/array_open_element.bend');
  const bad = await load(failureSource), before = checked(bad), failures: string[] = [];
  for (const emission of ['eager', 'deferred'] as const) {
    let caught: unknown;
    try { C.compile_book(bad, {emission}); } catch (error) { caught = error; }
    need(caught !== undefined, 'Invalid C unexpectedly succeeded');
    failures.push(diagnostic(caught));
    need(C.PROBES.length === 1 && checked(bad).every((body, i) => body === before[i]),
      'Failed C retained compiler state or changed checked bodies');
  }
  need(failures[0] === failures[1] && /open Array element type/.test(failures[0]), 'Failure diagnostic changed');
  const lateSource = join(output, 'bad_ids.bend');
  writeFileSync(lateSource, `import Base
def bad.ids(value: U32) -> IO(U32):
  import "./bad_ids.c"
def main() -> IO(Unit):
  do IO<Unit>:
    value : U32 <- bad.ids(1)
    IO.print(U32.show(value))
`, {flag: 'wx'});
  writeFileSync(join(output, 'bad_ids.c'), `
static Term bad_ids_run(Env e, Term* f, IoWork* w) { return f[0]; }
static void __attribute__((constructor)) bad_ids_use(void) {
  io_eff(CID(no_such_effect), bad_ids_run);
}
`, {flag: 'wx'});
  const late = await load(lateSource), lateBefore = checked(late), lateFailures: string[] = [];
  for (const emission of ['eager', 'deferred'] as const) {
    let caught: unknown;
    try { C.compile_book(late, {emission}); } catch (error) { caught = error; }
    need(caught !== undefined, 'Invalid foreign ID unexpectedly succeeded');
    lateFailures.push(diagnostic(caught));
    need(C.PROBES.length === 1 && checked(late).every((body, i) => body === lateBefore[i]),
      'Late C failure retained compiler state or changed checked bodies');
  }
  need(lateFailures[0] === lateFailures[1] && /names no constructor or def/.test(lateFailures[0]),
    'Late foreign validation changed');
  report.lateFailure = {source: lateSource, diagnostic: lateFailures[0], unchanged: true};
  const recovered = await load(collision);
  need(compile(recovered, 'eager').c === compile(recovered, 'deferred').c, 'Codegen failure contaminated recovery');
  report.failure = {source: failureSource, diagnostic: failures[0], unchanged: true};
  for (const [path, digest] of Object.entries(inputs)) need(sha(readFileSync(path)) === digest, 'Input drift: ' + path);
  report.status = 'PASS';
} catch (error) {
  report.status = 'FAIL'; report.error = diagnostic(error); process.exitCode = 1;
} finally {
  writeFileSync(join(output, 'report.json'), JSON.stringify(report, null, 2) + '\n', {flag: 'wx'});
  console.log(JSON.stringify({status: report.status, report: join(output, 'report.json'), error: report.error}));
}
