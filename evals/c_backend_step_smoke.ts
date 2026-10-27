#!/usr/bin/env bun
/** C backend exercised through the shared native step pipeline (real CLay + physical).
 *
 * This is the production admission pattern, not a second evaluator: the
 * canonical fixture imports the descriptor normalizer as a composed CPS
 * provider, generateNativeSteps factors every match/handler into an acyclic
 * step graph, and the only recursive definition is the operational Run chunk
 * (quantum 64, zero returns the remaining Run unchanged). The semantic
 * normalization fuel inside the source is untouched; this host drives the
 * chunks until the Run finishes and reads the fixture's result.
 *
 *   bun evals/descriptor_nf_step_smoke.ts            # generate step source
 *   bun evals/descriptor_nf_step_smoke.ts --run=ART  # drive a built artifact
 *
 * Generated files live under the gitignored checkpoints/ directory.
 */
import {createHash} from 'node:crypto';
import {readFileSync, writeFileSync} from 'node:fs';
import {dirname, posix, resolve} from 'node:path';
import {pathToFileURL} from 'node:url';
import {normalizeNativeMatchSource} from './native_match_source.ts';
import {composeCanonicalCPSSource} from './canonical_cps_source.ts';
import {checkerStepConfig, generateNativeSteps} from './checker_core_step_lower.ts';
import type {StepConfig} from './checker_core_step_lower.ts';

const canonical = 'evals/c_backend_smoke.bend';
const owned = 'checkpoints/c_backend_smoke_owned.bend';
const ownedManifest = 'checkpoints/c-backend-smoke-owned.json';
const dependency = 'checkpoints/c-backend-smoke-dependency.json';
const output = 'checkpoints/c_backend_steps_v1.bend';
const component = 'checkpoints/c_backend_steps_component_v1.bend';
const manifest = 'checkpoints/c-backend-steps-v1.json';
const providers = ['bend2/selfhost/c_backend.bend', 'bend2/selfhost/c_backend_layout.bend',
  'bend2/selfhost/c_backend_physical.bend', 'bend2/selfhost/descriptor_nf.bend',
  'bend2/selfhost/c_backend_link.bend',
  'evals/c_backend_runtime.bend'];
const expected = '26';
const sha = (text: string) => createHash('sha256').update(text).digest('hex');

/** Same masking rule as the step generator: coordinates stay intact, including
 * comment-looking text inside strings. */
function mask(text: string): string {
  let result = '', quote = '', escaped = false, comment = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i]!;
    if (comment) { if (c === '\n') { comment = false; result += c; } else result += ' '; }
    else if (quote) {
      result += c === '\n' ? '\n' : ' ';
      if (escaped) escaped = false;
      else if (c === '\\') escaped = true;
      else if (c === quote) quote = '';
    } else if (c === '"' || c === "'") { quote = c; result += ' '; }
    else if (c === '#' || text.startsWith('//', i)) { comment = true; result += ' '; }
    else result += c;
  }
  if (quote) throw Error('Unterminated string in ' + canonical);
  return result;
}
function declarations(text: string): {names: string[]; hashes: Record<string, string>} {
  const clean = mask(text), starts = [...clean.matchAll(/^def ([A-Za-z_]\w*)\(/gm)];
  const names = starts.map(match => match[1]!);
  return {names, hashes: Object.fromEntries(starts.map((match, index) =>
    [match[1]!, sha(text.slice(match.index!, starts[index + 1]?.index ?? text.length))]))};
}
/** The composed header spells external imports relative to the canonical; the
 * owned copy lives under checkpoints/, so re-spell them for its directory. */
function relocateImports(text: string): string {
  return text.replace(/^import (\S+) as ([A-Za-z_]\w*)$/gm, (_, imported: string, alias: string) => {
    const target = posix.join(dirname(canonical), imported);
    let relative = posix.relative(dirname(owned), target);
    if (!relative.startsWith('.')) relative = './' + relative;
    return 'import ' + relative + ' as ' + alias;
  });
}
async function generate(): Promise<StepConfig> {
  const canonicalText = readFileSync(canonical, 'utf8');
  const composition = await composeCanonicalCPSSource(canonical, providers);
  const normalized = await normalizeNativeMatchSource(canonical, composition.source);
  const ownedText = relocateImports(normalized.source);
  writeFileSync(owned, ownedText);
  writeFileSync(dependency, '{}\n');
  const lowered = declarations(composition.source);
  const normalizedDeclarations = declarations(ownedText);
  const original = declarations(canonicalText);
  const proof = {
    canonical, owned,
    canonicalSha256: sha(canonicalText),
    sourceSha256: sha(ownedText),
    definitionNames: normalizedDeclarations.names,
    declarationHashes: normalizedDeclarations.hashes,
    owners: Object.fromEntries(normalized.extractions.map(row => [row.helper, row.owner])),
    canonicalDefinitionNames: original.names,
    canonicalDeclarationHashes: original.hashes,
    loweringDefinitionNames: lowered.names,
    loweringDeclarationHashes: lowered.hashes,
    composition: composition.proof,
  };
  writeFileSync(ownedManifest, JSON.stringify({
    schemaVersion: 2, sourceOnlyParameterMatchFactoring: true,
    componentSources: [{mode: 'template', ...proof}], ownedModules: [],
  }, null, 2) + '\n');
  const config: StepConfig = {
    ...checkerStepConfig,
    mode: 'template', root: 'main', result: 'CBackendSmoke',
    canonical, owned, ownedManifest, dependency,
    generator: 'evals/c_backend_step_smoke.ts',
    output, component, manifest,
    driver: undefined, ownedDriver: undefined,
    providerClosure: providers,
  };
  await generateNativeSteps(config);
  return config;
}
type Chunk = {tag: string; fields: Record<string, unknown>};
function chunkOf(value: unknown): Chunk | null {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) return null;
  const fields = value as Record<string, unknown>;
  const tag = fields['$'];
  return typeof tag === 'string' ? {tag, fields} : null;
}
async function run(artifact: string): Promise<void> {
  // The artifact path is selected at runtime (--run=ART), so it cannot be a
  // static import; the module exports are then narrowed by chunkOf guards.
  const loaded: unknown = await import(pathToFileURL(resolve(artifact)).href);
  const exported = typeof loaded === 'object' && loaded !== null
    ? (loaded as {default?: unknown}).default ?? loaded : null;
  const api = typeof exported === 'object' && exported !== null ? exported as Record<string, unknown> : null;
  const start = api?.['expand_modules_start'], step = api?.['template_step'];
  if (typeof start !== 'function' || typeof step !== 'function') throw Error('Artifact is missing expand_modules_start/template_step');
  let steps = 0;
  let current: unknown = start(undefined);
  for (;;) {
    const chunk = chunkOf(current);
    if (!chunk) throw Error('Unexpected Run value ' + String(current));
    if (chunk.tag.split('.').at(-1) === 'TemplateRunState') {
      current = undefined;
      current = step(chunk.fields);
      steps += 1;
      if (steps > 100000000) throw Error('Template Run did not finish');
      continue;
    }
    if (chunk.tag.split('.').at(-1) !== 'TemplateRunFinished') throw Error('Unexpected Run tag ' + chunk.tag);
    const box = chunkOf(chunk.fields['box']);
    const value = box ? chunkOf(box.fields['value']) : null;
    const source = value?.fields['source'];
    if (typeof source !== 'string') {
      const message = value?.fields['message'];
      throw Error('CBackendSmoke result has no source string' + (typeof message === 'string' ? ': ' + message : ''));
    }
    writeFileSync('/tmp/c_backend_smoke.c', source);
    const build = Bun.spawnSync(['clang', '-std=c11', '-O0', '-o', '/tmp/c_backend_smoke', '/tmp/c_backend_smoke.c']);
    if (build.exitCode !== 0) throw Error('clang failed: ' + new TextDecoder().decode(build.stderr).slice(0, 2000));
    const run = Bun.spawnSync(['/tmp/c_backend_smoke']);
    const out = new TextDecoder().decode(run.stdout).trim();
    if (run.exitCode !== 0) throw Error('C smoke exited ' + run.exitCode + ': ' + new TextDecoder().decode(run.stderr).slice(0, 2000));
    if (out !== expected) throw Error('Observed ' + out + '; expected ' + expected);
    console.log(JSON.stringify({status: 'PASS', observed: out, bytes: source.length, chunks: steps, artifact: sha(readFileSync(artifact))}));
    return;
  }
}
if (import.meta.main) {
  const argument = process.argv.slice(2).find(value => value.startsWith('--run='));
  if (argument) await run(argument.slice('--run='.length));
  else {
    const config = await generate();
    console.log(JSON.stringify({generated: config.output, component: config.component,
      componentSha256: sha(readFileSync(config.component))}));
  }
}
