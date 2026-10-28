#!/usr/bin/env bun
/** Private-region scalarization regression through the production step seam.
 *
 * The canonical fixture is composed exactly like a production provider, then
 * generateNativeSteps applies the production private-region pass. Build the
 * resulting component with checker_core_component_build.ts and use --run to
 * execute it: the checked result must be "9". Manifest accounting is reported,
 * not treated as a substitute for canonical admission or runtime behavior.
 *
 *   bun evals/cps_region_scalarization_smoke.ts            # generate
 *   bun evals/cps_region_scalarization_smoke.ts --run=ART  # execute built ART
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

const canonical = 'evals/cps_region_scalarization.bend';
const owned = 'checkpoints/cps_region_scalarization_owned.bend';
const ownedManifest = 'checkpoints/cps-region-scalarization-owned.json';
const dependency = 'checkpoints/cps-region-scalarization-dependency.json';
const output = 'checkpoints/cps_region_scalarization_steps_v1.bend';
const component = 'checkpoints/cps_region_scalarization_component_v1.bend';
const manifest = 'checkpoints/cps-region-scalarization-steps-v1.json';
const expected = '9';
const sha = (text: string) => createHash('sha256').update(text).digest('hex');

/** Same coordinate-preserving mask as the generator. */
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
  if (quote) throw Error('Unterminated source string in ' + canonical);
  return result;
}
function declarations(text: string): {names: string[]; hashes: Record<string, string>} {
  const clean = mask(text), starts = [...clean.matchAll(/^def ([A-Za-z_]\w*)\(/gm)];
  const names = starts.map(match => match[1]!);
  return {names, hashes: Object.fromEntries(starts.map((match, index) =>
    [match[1]!, sha(text.slice(match.index!, starts[index + 1]?.index ?? text.length))]))};
}
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
  const composition = await composeCanonicalCPSSource(canonical, []);
  const normalized = await normalizeNativeMatchSource(canonical, composition.source);
  const ownedText = relocateImports(normalized.source);
  writeFileSync(owned, ownedText);
  writeFileSync(dependency, '{}\n');
  const lowered = declarations(composition.source);
  const normalizedDeclarations = declarations(ownedText);
  const original = declarations(canonicalText);
  const proof = {
    canonical, owned,
    canonicalSha256: sha(canonicalText), sourceSha256: sha(ownedText),
    definitionNames: normalizedDeclarations.names, declarationHashes: normalizedDeclarations.hashes,
    owners: Object.fromEntries(normalized.extractions.map(row => [row.helper, row.owner])),
    canonicalDefinitionNames: original.names, canonicalDeclarationHashes: original.hashes,
    loweringDefinitionNames: lowered.names, loweringDeclarationHashes: lowered.hashes,
  };
  writeFileSync(ownedManifest, JSON.stringify({
    schemaVersion: 2, sourceOnlyParameterMatchFactoring: true,
    componentSources: [{mode: 'template', ...proof}], ownedModules: [],
  }, null, 2) + '\n');
  const config: StepConfig = {
    ...checkerStepConfig,
    mode: 'template', root: 'main', result: 'RegionSmoke',
    canonical, owned, ownedManifest, dependency,
    generator: 'evals/cps_region_scalarization_smoke.ts',
    output, component, manifest, driver: undefined, ownedDriver: undefined,
    providerClosure: [],
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
  // The artifact path is selected at runtime (--run=ART); a static import
  // cannot name a module that does not exist until the build finishes.
  const loaded: unknown = await import(pathToFileURL(resolve(artifact)).href);
  const exported = typeof loaded === 'object' && loaded !== null && 'default' in loaded
    ? loaded.default : loaded;
  // Boundary cast: the module namespace is untyped at the dynamic-import edge;
  // every export is re-validated as a function before use.
  const api = typeof exported === 'object' && exported !== null ? exported as Record<string, unknown> : null;
  const start = api?.['expand_modules_start'], step = api?.['template_step'];
  if (typeof start !== 'function' || typeof step !== 'function')
    throw Error('Artifact is missing expand_modules_start/template_step');
  let steps = 0;
  let current: unknown = start(undefined);
  for (;;) {
    const chunk = chunkOf(current);
    if (!chunk) throw Error('Unexpected Run value ' + String(current));
    const tag = chunk.tag.split('.').at(-1);
    if (tag === 'TemplateRunState') {current = step(chunk.fields); steps++; continue;}
    if (tag !== 'TemplateRunFinished') throw Error('Unexpected Run tag ' + chunk.tag);
    const box = chunkOf(chunk.fields['box']);
    const value = box ? chunkOf(box.fields['value']) : null;
    const bits = value?.fields['bits'];
    if (typeof bits !== 'string' || bits !== expected) throw Error('Observed ' + String(bits) + '; expected ' + expected);
    console.log(JSON.stringify({status: 'PASS', bits, chunks: steps, artifact: sha(readFileSync(artifact))}));
    return;
  }
}
if (import.meta.main) {
  const argument = process.argv.slice(2).find(value => value.startsWith('--run='));
  if (argument) await run(argument.slice('--run='.length));
  else {
    const config = await generate();
    const accounting = JSON.parse(readFileSync(config.manifest, 'utf8')).privateRegionScalarization;
    console.log(JSON.stringify({generated: config.output, component: config.component,
      componentSha256: sha(readFileSync(config.component)), accounting}));
  }
}
