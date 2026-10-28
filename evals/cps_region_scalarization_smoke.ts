#!/usr/bin/env bun
/** Private-region scalarization regression through the production step seam.
 *
 * The canonical fixture is composed exactly like a production provider, then
 * generateNativeSteps factors matches/continuations and applies bounded
 * private-region inlining plus quantity-checked alias scalarization. This
 * script is a consumer, not a second compiler: it re-checks the generated
 * artifact against the canonical source grammar constraints the native
 * admission enforces (matches before locals in one scope, dependency-first
 * declarations, unique declaration names) and against the manifest's own
 * accounting, then optionally drives a built artifact to its result.
 *
 *   bun evals/cps_region_scalarization_smoke.ts            # generate + audit
 *   bun evals/cps_region_scalarization_smoke.ts --run=ART  # drive built ART
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
/** Every declaration owns one indentation scope chain: within one scope a
 * `match` statement may not follow a local binding. Row bodies are deeper
 * indentation and therefore fresh scopes, exactly like the canonical parser. */
function auditGrammar(text: string): void {
  const clean = mask(text);
  const lines = clean.split('\n');
  const starts = [...clean.matchAll(/^def ([A-Za-z_]\w*)\(/gm)];
  const positions = new Map(starts.map((match, index) => [match[1]!, index] as const));
  const seen = new Set<string>();
  for (const match of starts) {
    if (seen.has(match[1]!)) throw Error('Duplicate generated declaration ' + match[1]);
    seen.add(match[1]!);
  }
  for (let index = 0; index < starts.length; index++) {
    const begin = clean.slice(0, starts[index]!.index).split('\n').length - 1;
    const end = index + 1 < starts.length
      ? clean.slice(0, starts[index + 1]!.index).split('\n').length - 1 : lines.length;
    let bindings = new Set<number>();
    for (let line = begin + 1; line < end; line++) {
      const value = lines[line]!;
      if (!value.trim()) continue;
      const indent = value.length - value.trimStart().length;
      for (const scope of [...bindings]) if (scope > indent) bindings.delete(scope);
      const body = value.trim();
      if (body.startsWith('match ')) {
        if (bindings.has(indent)) throw Error('Local-before-match at ' + starts[index]![1] + ' line ' + (line + 1));
        continue;
      }
      if (body.startsWith('case ') || body.startsWith('type ') || body.startsWith('import ')) continue;
      if (/^(?:-?[+A-Za-z_{(].*?)\s=\s/.test(body)) bindings.add(indent);
      for (const call of body.matchAll(/(?<![\w.])([A-Za-z_]\w*)\(/g)) {
        const at = positions.get(call[1]!);
        if (at !== undefined && at > index) throw Error('Forward private declaration ' + call[1] + ' in ' + starts[index]![1]);
      }
    }
  }
}
function audit(config: StepConfig): Record<string, unknown> {
  const source = readFileSync(config.output, 'utf8');
  const generated = JSON.parse(readFileSync(config.manifest, 'utf8'));
  const section = generated.privateRegionScalarization;
  if (!section) throw Error('Manifest has no privateRegionScalarization accounting');
  if (!Array.isArray(section.sites) || section.sites.length === 0) throw Error('No private helper was inlined');
  if (!(section.eliminatedAliasBindings > 0)) throw Error('No scalar alias was eliminated');
  if (!(section.helpersAfter < section.helpersBefore)) throw Error('Helper count did not fall');
  if (!section.sites.some((site: {kind: string}) => site.kind === 'ordered-match' || site.kind === 'pure-ordered-match'))
    throw Error('Fixture root match was not inlined into its handler');
  for (const site of section.sites) {
    if (new RegExp('^def ' + site.helper.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '\\(', 'm').test(source))
      throw Error('Inlined helper still has a declaration: ' + site.helper);
  }
  auditGrammar(source);
  return {sites: section.sites.length, aliases: section.eliminatedAliasBindings,
    helpersBefore: section.helpersBefore, helpersAfter: section.helpersAfter,
    rejected: section.rejectedSites};
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
    const accounting = audit(config);
    console.log(JSON.stringify({generated: config.output, component: config.component,
      componentSha256: sha(readFileSync(config.component)), accounting}));
  }
}
