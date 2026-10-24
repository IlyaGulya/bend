/**
 * Library export boundary run: composes the canonical library smoke with the
 * same provider closure as the executable smoke, builds it as a native
 * component, writes the single C translation unit, links the C caller that
 * drives bend_export_call/apply, and runs it.
 *
 * The C unit is the renderer's own source; the caller may keep its own main
 * because the library renderer renames the runtime's main.
 */
import {readFileSync, writeFileSync} from 'node:fs';
import {dirname, posix, resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
import {composeCanonicalCPSSource} from './canonical_cps_source.ts';
import {normalizeNativeMatchSource} from './native_match_source.ts';

const canonical = 'evals/c_backend_library_smoke.bend';
const owned = 'checkpoints/c_backend_library_owned.bend';
const artifact = '/tmp/c_backend_library.mjs';
const report = 'checkpoints/c-backend-library-build';
const providers = ['bend2/selfhost/c_backend.bend', 'bend2/selfhost/c_backend_layout.bend',
  'bend2/selfhost/c_backend_physical.bend', 'bend2/selfhost/descriptor_nf.bend',
  'bend2/selfhost/c_backend_link.bend', 'bend2/selfhost/backend_ir.bend',
  'bend2/selfhost/index_lookup.bend', 'bend2/selfhost/c_backend_sharing.bend',
  'evals/c_backend_runtime.bend'];

function relocateImports(text: string): string {
  return text.replace(/^import (\S+) as ([A-Za-z_]\w*)$/gm, (_, imported: string, alias: string) => {
    const target = posix.join(dirname(canonical), imported);
    let relative = posix.relative(dirname(owned), target);
    if (!relative.startsWith('.')) relative = './' + relative;
    return 'import ' + relative + ' as ' + alias;
  });
}

const composition = await composeCanonicalCPSSource(canonical, providers);
const normalized = await normalizeNativeMatchSource(canonical, composition.source);
writeFileSync(owned, relocateImports(normalized.source));

const build = Bun.spawnSync(['node', '--experimental-strip-types', '--max-old-space-size=3072',
  'evals/checker_core_component_build.ts', '--file=' + owned, '--exports=rendered',
  '--artifact=' + artifact, '--report=' + report], {stdout: 'pipe', stderr: 'pipe'});
if (build.exitCode !== 0) {
  console.error(new TextDecoder().decode(build.stderr).slice(0, 3000));
  console.error(new TextDecoder().decode(build.stdout).slice(0, 1000));
  throw Error('component build failed');
}

const loaded: unknown = await import(pathToFileURL(resolve(artifact)).href + '?t=' + Date.now());
const api = loaded as {default?: unknown} & Record<string, unknown>;
const table = (typeof api.default === 'object' && api.default !== null ? api.default : api) as Record<string, unknown>;
const rendered = table['rendered'];
if (typeof rendered !== 'function') throw Error('artifact has no rendered export');
const source = (rendered as () => string)();
if (source.startsWith('ERROR: ')) throw Error('render failed: ' + source.slice(7));

writeFileSync('/tmp/c_backend_library.c', source);
writeFileSync('/tmp/c_backend_library_caller.c', readFileSync('evals/c_backend_library_caller.c', 'utf8'));
const cc = Bun.spawnSync(['clang', '-std=c11', '-O0', '-o', '/tmp/c_backend_library',
  '/tmp/c_backend_library.c', '/tmp/c_backend_library_caller.c'], {stdout: 'pipe', stderr: 'pipe'});
if (cc.exitCode !== 0) {
  console.error(new TextDecoder().decode(cc.stderr).slice(0, 4000));
  throw Error('clang failed');
}
const run = Bun.spawnSync(['/tmp/c_backend_library'], {stdout: 'pipe', stderr: 'pipe'});
const out = new TextDecoder().decode(run.stdout).trim();
if (run.exitCode !== 0) {
  console.error(new TextDecoder().decode(run.stderr).slice(0, 2000));
  throw Error('library run exited ' + run.exitCode);
}
if (out !== 'export ok') throw Error('observed ' + out);
console.log(JSON.stringify({status: 'PASS', observed: out, bytes: source.length}));
