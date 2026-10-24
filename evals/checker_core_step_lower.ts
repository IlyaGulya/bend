#!/usr/bin/env bun
/** Lower authenticated canonical functions into typed, bounded native chunks.
 * CLI: bun evals/checker_core_step_lower.ts; emitter: bun evals/emitter_step_lower.ts;
 * template: bun evals/template_step_lower.ts. All entries share this Body-AST/CPS
 * implementation and generate source only. Exact-content complete-input manifest
 * reuse saves generation, never native validation; canonical schema4 builds check
 * every generated body afterward. The host drives requests, not algorithms.
 */
import {createHash, randomUUID} from 'node:crypto';
import {existsSync, readFileSync, realpathSync, writeFileSync, rmSync} from 'node:fs';
import {dirname, posix, resolve} from 'node:path';
import {homedir} from 'node:os';
import * as B from '../bend2/bend.ts';
import type {ParserParameter, ParserSignature} from './parser_full_graph.ts';
import {renderBody} from './parser_full_body_render.ts';
import {LexicalTypes, freeBinderIds, termChildren, type Binding} from './parser_full_type_env.ts';
import {composeCanonicalCPSSource, type CPSProviderClosure} from './canonical_cps_source.ts';

export const checkerStepConfig = {
  canonical: 'bend2/selfhost/checker.bend', owned: 'checkpoints/checker_core_owned_v1.bend',
  dependency: 'checkpoints/checker-core-dependency.json', ownedManifest: 'checkpoints/checker-core-owned-source-v1.json',
  ownedDriver: 'checkpoints/checker_core_owned_driver_v1.bend',
  frozenSlice: 'checkpoints/checker_core_slice.bend', frozenDriver: 'checkpoints/checker_core_driver.bend',
  frozenCorpus: 'checkpoints/bootstrap-real-source-corpus.json',
  kernel: 'bend2/bend.ts', emitter: 'bend2/comp.ts', parser: 'bend2/selfhost/parser.bend', base: 'bend2/base.bend',
  nodePolicy: 'evals/heavy_gate.ts', validationPolicy: 'evals/validation_profile.ts',
  generator: 'evals/checker_core_step_lower.ts',
  output: 'checkpoints/checker_core_steps_v1.bend',
  component: 'checkpoints/checker_core_steps_component_v1.bend',
  driver: 'checkpoints/checker_core_steps_driver_v1.bend', manifest: 'checkpoints/checker-core-steps-v1.json',
  mode: 'checker', root: 'check_modules', result: 'Checked.CheckResult',
} as const;
/** One native emitter entry path inside a shared generated composition. */
export type StepEntry = {mode: 'emitter' | 'cemit'; root: string; libraryRoot: string};
export type StepConfig = {
  canonical: string; owned: string; dependency: string; ownedManifest: string; ownedDriver?: string;
  frozenSlice: string; frozenDriver: string; frozenCorpus: string;
  kernel: string; emitter: string; parser: string; base: string;
  nodePolicy: string; validationPolicy: string;
  output: string; component: string; driver?: string; manifest: string;
  mode: 'checker' | 'emitter' | 'template'; root: string; result: string;
  /** Entire canonical provider modules admitted into the same typed CPS boundary. */
  providerClosure?: CPSProviderClosure;
  /** Every target entry path in one generated composition. When present the
   * module is generated once for all entries and uses this config's protocol
   * (mode `emitter` keeps the established Emitter Run tags). */
  entries?: readonly StepEntry[];
  /** Component alias; defaults to the historical per-mode alias. */
  componentAlias?: string;
  /** Retained for callers that set it, but the composer now orders composed
   * datatypes by dependency SCC itself: dependency-first across acyclic groups and
   * source order inside one genuinely mutual group, so no flag is needed. */
  sourceOrderedDatatypes?: boolean;
  generator: string;
};
export async function generateNativeSteps(paths: StepConfig) {
const protocol = paths.mode === 'checker' ? 'Checker' : paths.mode === 'emitter' ? 'Emitter' : 'Template';
const prefix = paths.mode;
const requestType = protocol + 'Request', progressType = protocol + 'Progress', valueType = protocol + 'Value';
const finishedType = protocol + 'Finished', pendingType = protocol + 'Pending', directType = protocol + 'Direct', boundType = protocol + 'Bound';
const stackType = protocol + 'Stack', stackDoneType = protocol + 'StackDone', stackMoreType = protocol + 'StackMore';
const runType = protocol + 'Run', runFinishedType = protocol + 'RunFinished', runStateType = protocol + 'RunState';
const castBoxFunction = prefix + '_cast_box', popFunction = prefix + '_pop', advanceFunction = prefix + '_advance';
const resultFunction = prefix + '_result', stepFunction = prefix + '_step', startFunction = prefix + '_start';
const rawStepFunction = prefix + '_step_one', chunkFunction = prefix + '_chunk', nativeChunkQuantum = 64;
const unboxFunction = prefix + '_unbox';
const entries: readonly StepEntry[] | undefined = paths.entries ?? (paths.mode === 'emitter'
  ? [{mode: 'emitter', root: paths.root, libraryRoot: 'emit_library'}] : undefined);
const startNames = entries ? entries.flatMap(entry => entry.mode === 'emitter'
  ? ['emitter_start', 'emitter_library_start'] : ['cemit_start', 'cemit_library_start']) : [];
const inputPaths: string[] = [paths.canonical, paths.owned, paths.dependency, paths.frozenSlice, paths.frozenDriver,
  paths.frozenCorpus, paths.kernel, paths.emitter, paths.parser, paths.base, paths.nodePolicy, paths.validationPolicy,
  paths.ownedManifest, ...(paths.ownedDriver ? [paths.ownedDriver] : [])];
const inputs = new Map(inputPaths.map(path => [path, readFileSync(path, 'utf8')]));
for (const path of ['evals/checker_core_step_lower.ts', 'evals/checker_core_owned_source.ts', 'evals/emitter_step_lower.ts', 'evals/template_step_lower.ts',
  'bend2/bend.ts', 'evals/parser_full_graph.ts', 'evals/parser_full_body_render.ts', 'evals/parser_full_type_env.ts',
  'evals/native_match_source.ts', 'evals/parser_full_declarations.ts', 'evals/bootstrap_source_oracle.ts', 'evals/canonical_cps_source.ts',
  ...(paths.generator ? [paths.generator] : [])]) {
  if (!inputs.has(path)) {inputPaths.push(path); inputs.set(path, readFileSync(path, 'utf8'));}
}
const ownedSource = inputs.get(paths.owned)!;
let source = ownedSource;
const sha = (text: string) => createHash('sha256').update(text).digest('hex');
const generationConfig = Object.fromEntries(Object.keys(paths).sort().map(key => [key, paths[key as keyof StepConfig]]).filter(([, value]) => value !== undefined));
const generationEnvironment = {
  cwd: process.cwd(), base: B.BASE_BEND,
  library: resolve(process.env.BEND_LIB ?? posix.join(homedir(), '.bend', 'lib')), hub: B.BEND_HUB,
  runtime: Object.fromEntries(Object.entries(process.versions).sort(([a], [b]) => a.localeCompare(b))),
};
function writeChanged(path: string, text: string) {
  if (!existsSync(path) || readFileSync(path, 'utf8') !== text) writeFileSync(path, text);
}
// Same coordinate-preserving lexical mask and raw telescope/Body boundary as
// checker_core_scc_lower.ts. It never guesses whether a spelling is a call.
function mask(text: string): string {
  let out = '', quote = '', escaped = false, comment = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i]!;
    if (comment) {if (c === '\n') {comment = false; out += c;} else out += ' ';}
    else if (quote) {
      out += c === '\n' ? '\n' : ' ';
      if (escaped) escaped = false; else if (c === '\\') escaped = true; else if (c === quote) quote = '';
    } else if (c === '"' || c === "'") {quote = c; out += ' ';}
    else if (c === '#' || text.startsWith('//', i)) {comment = true; out += ' ';}
    else out += c;
  }
  if (quote) throw Error('Unterminated source string');
  return out;
}
let clean = mask(source), starts = [...clean.matchAll(/^def ([A-Za-z_]\w*)\(/gm)];
let names = new Set(starts.map(match => match[1]!));
const ownedManifest = JSON.parse(inputs.get(paths.ownedManifest)!);
if (!ownedManifest || ownedManifest.schemaVersion !== 2 || ownedManifest.sourceOnlyParameterMatchFactoring !== true)
  throw Error('Authentic native-match owned-source manifest required for every typed component');
const componentProof = paths.mode === 'checker' ? {
  canonical: ownedManifest.source, owned: ownedManifest.slice, canonicalSha256: ownedManifest.sourceSha256,
  sourceSha256: ownedManifest.sliceSha256, definitionNames: ownedManifest.normalizedDefinitionNames,
  declarationHashes: ownedManifest.normalizedDeclarationHashes, owners: ownedManifest.normalizedOwners,
  canonicalDefinitionNames: ownedManifest.definitionNames,
  canonicalDeclarationHashes: Object.fromEntries(ownedManifest.rootClosure.map((row: {name:string;exactCanonicalBlockSha256:string})=>[row.name,row.exactCanonicalBlockSha256])),
} : ownedManifest.componentSources.find((row: {mode:string})=>row.mode===paths.mode);
if (!componentProof || componentProof.canonical !== paths.canonical || componentProof.owned !== paths.owned
  || componentProof.sourceSha256 !== sha(source) || !Array.isArray(componentProof.definitionNames)
  || new Set(componentProof.definitionNames).size !== names.size || starts.length !== names.size
  || [...names].some(name=>!componentProof.definitionNames.includes(name)))
  throw Error('Complete normalized '+protocol+' declaration coverage/provenance drift');
for(const owned of ownedManifest.ownedModules){
  for(const[path,hash]of [[owned.source,owned.sourceSha256],[owned.output,owned.outputSha256]]){
    const text=inputs.get(path)??readFileSync(path,'utf8');
    if(sha(text)!==hash)throw Error('Owned module identity/provenance drift '+path);
    if(!inputs.has(path)){inputPaths.push(path);inputs.set(path,text);}
  }
}
if(paths.ownedDriver&&(ownedManifest.driver!==paths.ownedDriver||ownedManifest.driverSha256!==sha(inputs.get(paths.ownedDriver)!)))
  throw Error('Owned driver provenance drift');
if (/^(type|law) /m.test(clean.slice(starts[0]!.index))) throw Error('Unsupported interleaved declarations');
const header = source.slice(0, starts[0]!.index);
if (paths.mode === 'checker' && /^import .* as Template$/m.test(header)) throw Error('CheckerCore must not import Template');
const canonical = inputs.get(paths.canonical)!;
if (componentProof.canonicalSha256 !== sha(canonical)) throw Error('Owned component is not pinned to its current canonical source');
const originalStarts = [...mask(canonical).matchAll(/^def ([A-Za-z_]\w*)\(/gm)];
const originalBlocks = new Map(originalStarts.map((match, i) => [match[1]!, canonical.slice(match.index, originalStarts[i + 1]?.index ?? canonical.length)]));
for(const name of componentProof.canonicalDefinitionNames)
  if(componentProof.canonicalDeclarationHashes[name]!==sha(originalBlocks.get(name)??''))
    throw Error('Canonical declaration provenance drift '+name);
const composition = paths.providerClosure?.length
  ? await composeCanonicalCPSSource(paths.canonical, paths.providerClosure) : undefined;
if(JSON.stringify(componentProof.composition)!==JSON.stringify(composition?.proof))
  throw Error('Canonical provider closure/composition provenance drift');
if(composition)for(const[path,text]of composition.inputs){
  if(inputs.has(path)&&inputs.get(path)!==text)throw Error('Composed source input changed '+path);
  if(!inputs.has(path)){inputPaths.push(path);inputs.set(path,text);}
}
const loweringCanonical=composition?.source??canonical;
const canonicalStarts = [...mask(loweringCanonical).matchAll(/^def ([A-Za-z_]\w*)\(/gm)];
const canonicalBlocks = new Map(canonicalStarts.map((match, i) => [match[1]!, loweringCanonical.slice(match.index, canonicalStarts[i + 1]?.index ?? loweringCanonical.length)]));
const canonicalNames=new Set<string>(composition?componentProof.loweringDefinitionNames:componentProof.canonicalDefinitionNames);
const loweringDeclarationHashes:Record<string,string>=composition?componentProof.loweringDeclarationHashes:componentProof.canonicalDeclarationHashes;
if(composition&&(canonicalStarts.length!==canonicalNames.size
  ||composition.proof.declarations.filter(row=>row.kind==='def').length!==canonicalNames.size))
  throw Error('Complete canonical provider declaration coverage drift');
for(const name of canonicalNames)if(!names.has(name)||loweringDeclarationHashes[name]!==sha(canonicalBlocks.get(name)??''))
  throw Error('Authenticated CPS declaration lost or changed during native match ownership '+name);
for(const name of names)if(!canonicalNames.has(name)&&!canonicalNames.has(componentProof.owners[name]))
  throw Error('Normalized helper has no authenticated canonical owner '+name);
// CPS consumes either exact original blocks or explicitly authenticated AST
// composition blocks. Provider canonical hashes remain separate and unchanged;
// native-only factoring helpers never masquerade as canonical declarations.
source = header + [...canonicalNames].map(name => canonicalBlocks.get(name)!).join('');
clean = mask(source);
starts = [...clean.matchAll(/^def ([A-Za-z_]\w*)\(/gm)];
names = new Set(starts.map(match => match[1]!));
if (starts.length !== canonicalNames.size || names.size !== canonicalNames.size
  || [...names].some(name => !canonicalNames.has(name)))
  throw Error('Authenticated CPS declaration coverage drift');
const aliases: Record<string, string> = Object.create(null);
for (const match of header.matchAll(/^import (\S+) as ([A-Za-z_]\w*)$/gm)) aliases[match[2]!] = posix.normalize(match[1]!).replace(/\.bend$/, '');
for (const imported of Object.values(aliases)) {
  const path = posix.normalize(posix.join(dirname(paths.owned), imported + '.bend'));
  if (!inputs.has(path)) {inputPaths.push(path); inputs.set(path, readFileSync(path, 'utf8'));}
}
// Only a complete successful generation writes this digest. Older, malformed,
// changed or missing manifests fall through to full AST/provenance generation.
// Stored import paths include the entire Book closure, not just used providers;
// realpath identity also pins the loader's namespace/cycle deduplication.
function reuseGeneration() {
  if (!existsSync(paths.manifest)) return;
  try {
    const manifestText = readFileSync(paths.manifest, 'utf8');
    const cached = JSON.parse(manifestText);
    const {generationManifestSha256, ...authenticated} = cached;
    if (generationManifestSha256 !== sha(JSON.stringify(authenticated))
      || JSON.stringify(cached.generationConfig) !== JSON.stringify(generationConfig)
      || JSON.stringify(cached.generationEnvironment) !== JSON.stringify(generationEnvironment)) return;
    const hashes = cached.protectedUnchangedHashes, realpaths = cached.generationInputRealpaths;
    if (!hashes || !realpaths || typeof hashes !== 'object' || typeof realpaths !== 'object'
      || Object.keys(hashes).sort().join('\n') !== Object.keys(realpaths).sort().join('\n')) return;
    const snapshots = new Map<string, string>(inputs);
    for (const [path, text] of inputs) if (hashes[path] !== sha(text)) return;
    for (const [path, hash] of Object.entries(hashes)) {
      const text = snapshots.get(path) ?? readFileSync(path, 'utf8');
      if (typeof hash !== 'string' || sha(text) !== hash || realpathSync(path) !== realpaths[path]) return;
      snapshots.set(path, text);
    }
    const outputPaths = [paths.output, paths.component, ...(paths.driver ? [paths.driver] : [])];
    if (!cached.outputs || Object.keys(cached.outputs).sort().join('\n') !== [...outputPaths].sort().join('\n')) return;
    const outputSnapshots = new Map(outputPaths.map(path => [path, readFileSync(path, 'utf8')]));
    for (const [path, text] of outputSnapshots) if (cached.outputs[path] !== sha(text)) return;
    // As on the generation path, reject changes during the invocation rather
    // than publishing a result based on mixed input/output snapshots.
    for (const [path, text] of snapshots) if (readFileSync(path, 'utf8') !== text || realpathSync(path) !== realpaths[path]) return;
    for (const [path, text] of outputSnapshots) if (readFileSync(path, 'utf8') !== text) return;
    if (readFileSync(paths.manifest, 'utf8') !== manifestText) return;
    console.log(JSON.stringify({source: paths.output, definitions: cached.definitionCount,
      sourceCalls: cached.sourceCallCount, pendingSites: cached.pendingSiteCount, lazyChoices: cached.lazyBoolPickCount,
      helpers: cached.definitionCount + cached.privateHelpers.length, manifest: paths.manifest, reused: true,
      generationManifestSha256, authenticatedInputs: snapshots.size, authenticatedOutputs: outputSnapshots.size}));
    return cached;
  } catch {
    // Cache metadata/output availability is optional; normal generation remains
    // the authority and retains all source callgraph and provider checks.
    return;
  }
}
const reused = reuseGeneration();
if (reused) return reused;
// Mirror book_load's import-prefix resolution, without parsing any bodies, to
// authenticate every logical import path (including unused/transitive imports).
// Capture before Book loading and recheck before publishing: absent dependencies
// fail closed rather than authenticating a provider loaded from different bytes.
const importPaths = new Set<string>();
function recordImports(path: string, text: string) {
  for (const rawLine of text.split('\n')) {
    const line = rawLine.trim(), match = /^import(\s.*|)$/.exec(line);
    if (!match) {if (line !== '' && !line.startsWith('#')) break; continue;}
    const imported = /^\s+(\S+)(?:\s+as\s+([A-Za-z_][A-Za-z0-9_]*))?\s*(?:#.*)?$/.exec(match[1]!);
    if (!imported || (imported[2] === undefined && imported[1] !== 'Base')) throw Error('Import provenance drift: ' + path);
    const rel = posix.normalize(imported[1]!);
    const target = imported[2] === undefined ? B.BASE_BEND
      : /^0x[0-9a-f]+\//.test(rel) ? posix.join(generationEnvironment.library, rel)
      : rel.startsWith('/') ? rel : posix.join(dirname(realpathSync(path)), rel);
    if (importPaths.has(target)) continue;
    importPaths.add(target);
    const child = inputs.get(target) ?? readFileSync(target, 'utf8');
    if (!inputs.has(target)) {inputPaths.push(target); inputs.set(target, child);}
    recordImports(target, child);
  }
}
recordImports(resolve(paths.owned), header);
const generationInputRealpaths = Object.fromEntries([...inputs.keys()].map(path => [path, realpathSync(path)]));
const book = B.book_nil(), temporary = resolve(dirname(paths.owned), '.checker_core_step_datatypes_' + randomUUID() + '.bend');
try {writeFileSync(temporary, header); await B.book_load(book, temporary, '', new Map());}
finally {rmSync(temporary, {force: true});}
const surfaceFile={str:source,ns:'',al:aliases};
function printedKey(key: string) {
  return B.name_show(surfaceFile,key);
}
function showTerm(term: B.LTerm, bound: string[], precedence: number): string {
  return B.term_show(term,precedence,bound,surfaceFile);
}
type Definition = ParserSignature & {name: string; body: B.Body; block: string; begin: number; end: number; resultSource: string};
const normalizations: object[] = [], effects: {caller: string; callee: string; offset: number; line: number; context: string; erased: boolean}[] = [];
function fail(name: string, reason: string, term?: B.LTerm): never {
  const offset = term?.s?.beg;
  throw Error(`${name}: ${reason}${offset === undefined ? '' : ` at line ${source.slice(0, offset).split('\n').length} (offset ${offset})`}`);
}
const definitions: Definition[] = starts.map((start, index) => {
  const name = start[1]!, begin = start.index!, end = starts[index + 1]?.index ?? source.length;
  const block = source.slice(begin, end);
  if(loweringDeclarationHashes[name]!==sha(block))fail(name,'CPS declaration is not authenticated by its canonical source/composition manifest');
  const signature = /^def [A-Za-z_]\w*\((.*)\) -> (.*):$/.exec(source.slice(begin, source.indexOf('\n', begin)));
  if (!signature) fail(name, 'Unsupported signature layout');
  const p: B.Parse = {book, dir: resolve(dirname(paths.owned)) + '/', str: source, pos: begin,
    stk: [], frs: 0, ns: '', al: aliases};
  if (!B.parse_word(p, 'def') || B.parse_name(p) !== name) fail(name, 'Raw parser boundary drift');
  B.parse_eat(p, '('); const parameters = B.parse_tele(p, ')');
  B.parse_eat(p, '->'); let result = B.parse_term(p); B.parse_eat(p, ':'); let body = B.parse_body(p);
  let env: B.Env = null;
  for (const parameter of parameters) {
    parameter[3] = B.term_lower(B.term_higher(parameter[3], env), p.frs);
    env = B.list_set(env, parameter[2], B.Var(parameter[1], parameter[2]));
  }
  result = B.term_lower(B.term_higher(result, env), p.frs);
  function extend(patterns: B.Patt[], input: B.Env): B.Env {
    let inner = input;
    function bind(pattern: B.Patt) {
      if (pattern.$ === 'PVar') {
        if (names.has(pattern.k)) fail(name, 'Checker function shadowed by local binder ' + pattern.k);
        inner = B.list_set(inner, pattern.i, B.Var(pattern.k, pattern.i));
      } else pattern.x.forEach(bind);
    }
    patterns.forEach(bind); return inner;
  }
  function resolveBody(node: B.Body, scope: B.Env): B.Body {
    const lower = (term: B.LTerm) => B.term_lower(B.term_higher(term, scope), p.frs);
    if (node.$ === 'Local') {node.v = node.v.map(lower); node.f = resolveBody(node.f, extend(node.k, scope));}
    else if (node.$ === 'Match') {node.e = node.e.map(lower); node.r.forEach(row => {row.f = resolveBody(row.f, extend(row.p, scope));});}
    else return lower(node);
    return node;
  }
  parameters.forEach(parameter => {if (names.has(parameter[1])) fail(name, 'Checker function shadowed by parameter');});
  body = resolveBody(body, env);
  return {name, parameters, result, body, block, begin, end, resultSource: signature![2]!};
});
const byName = new Map(definitions.map(def => [def.name, def]));
const unresolved: {definition: string; reference: string; line?: number; offset?: number}[] = [];
const invalidCalls: {definition: string; callee: string; supplied: number; required: number; line?: number}[] = [];
const providers = new Set<string>();
for (const def of definitions) {
  function visit(term: B.LTerm) {
    if (term.$ === 'App') {
      const [head, args] = B.term_unapply(term);
      if (head.$ === 'Ref' && names.has(head.k)) {
        const required = byName.get(head.k)!.parameters.length;
        if (args.length !== required) invalidCalls.push({definition: def.name, callee: head.k, supplied: args.length, required,
          line: head.s ? source.slice(0, head.s.beg).split('\n').length : undefined});
      }
      visit(head); args.forEach(visit); return;
    }
    if ((term.$ === 'Ref' || term.$ === 'ADT' || term.$ === 'Ctr') && !names.has(term.k)) {
      const declaration = book.tlds[term.k] ?? book.ctrs[term.k];
      if (!declaration) fail(def.name, 'Missing authenticated Book provider ' + printedKey(term.k), term);
      if (term.$ === 'ADT' && (book.tlds[term.k]?.$ !== 'ADT' || declaration.n !== term.x.length))
        fail(def.name, 'Native datatype descriptor parameter drift ' + printedKey(term.k), term);
      providers.add(term.k);
    }
    if (term.$ === 'Ref' && !names.has(term.k) && !book.tlds[term.k] && !book.ctrs[term.k]) unresolved.push({
      definition: def.name, reference: printedKey(term.k), offset: term.s?.beg,
      line: term.s ? source.slice(0, term.s.beg).split('\n').length : undefined,
    });
    termChildren(term).forEach(visit);
  }
  function visitBody(body: B.Body) {
    (body.$ === 'Local' ? body.v : body.$ === 'Match' ? body.e : [body]).forEach(visit);
    if (body.$ === 'Local') visitBody(body.f); else if (body.$ === 'Match') body.r.forEach(row => visitBody(row.f));
  }
  def.parameters.forEach(parameter => visit(parameter[3])); visit(def.result); visitBody(def.body);
}
if (unresolved.length || invalidCalls.length) throw Error('Unauthenticated source context: ' + JSON.stringify({unresolved, invalidCalls}));
// Authenticate constructor-call sugar with Book.ctrs; ordinary Ref calls are
// never converted by spelling. Preserve all supplied fields and reject arity drift.
function normalize(term: B.LTerm, def: Definition, context: string, erased = false): B.LTerm {
  if ((term.$ === 'Lam' && !erased) || term.$ === 'Mat' || term.$ === 'Rwt' || term.$ === 'Let' || term.$ === 'Sub')
    fail(def.name, 'Unsupported term context ' + term.$, term);
  if (term.$ === 'App') {
    const [head, args] = B.term_unapply(term);
    if (head.$ === 'Ref' && names.has(head.k)) {
      const target = byName.get(head.k)!;
      if (args.length !== target.parameters.length) fail(def.name, `Checker call ${head.k} supplies ${args.length}/${target.parameters.length} arguments (lowering never supplies missing arguments)`, head);
      if (context === 'signature') fail(def.name, 'Checker effect in signature', head);
      if (!head.s || head.s.file.str !== source || source.slice(head.s.beg, head.s.beg + head.k.length) !== head.k) fail(def.name, 'Unauthenticated checker call provenance', head);
      effects.push({caller: def.name, callee: head.k, offset: head.s.beg, line: source.slice(0, head.s.beg).split('\n').length, context, erased});
      if (erased) fail(def.name, 'Unsupported checker request in erased expression context', head);
      return args.reduce<B.LTerm>((fn, arg, i) => ({$: 'App', f: fn, x: normalize(arg, def, context + '/argument', erased || target.parameters[i]![0].$ === 'None'), s: term.s}), head);
    }
    if (head.$ === 'Ref' && /(?:^|\.)List\.(map|fold|filter|any|all)$/.test(head.k)) fail(def.name, 'Unsupported higher-order imported operation ' + head.k, head);
    if (head.$ === 'Ref' && book.ctrs[head.k]) {
      const constructor = book.ctrs[head.k]!;
      if (args.length !== constructor.n) fail(def.name, 'Constructor native field arity drift ' + head.k, head);
      normalizations.push({definition: def.name, constructor: printedKey(head.k), offset: head.s?.beg, fields: args.length, from: 'parentheses', to: 'native-field-braces'});
      return {$: 'Ctr', k: head.k, x: args.map(arg => normalize(arg, def, context + '/constructor', erased)), s: term.s};
    }
    const normalizedHead = normalize(head, def, context + '/head', erased);
    return args.reduce<B.LTerm>((fn, arg) => ({$: 'App', f: fn, x: normalize(arg, def, context + '/argument', erased), s: term.s}), normalizedHead);
  }
  if (term.$ === 'Ref' && names.has(term.k)) {
    if (byName.get(term.k)!.parameters.length) fail(def.name, 'Unsupported unsaturated checker reference ' + term.k, term);
    if (context === 'signature' || erased) fail(def.name, 'Unsupported nullary request in erased/signature context', term);
    // Native zero-parameter defs are values: bare Ref and foo() parse identically.
    // Authenticate the actual source reference and the zero arity, not trivia.
    if (!term.s || term.s.file.str !== source || source.slice(term.s.beg, term.s.beg + term.k.length) !== term.k)
      fail(def.name, 'Unauthenticated nullary source reference', term);
    effects.push({caller: def.name, callee: term.k, offset: term.s.beg, line: source.slice(0, term.s.beg).split('\n').length, context, erased});
    return term;
  }
  if (term.$ === 'Ref' && !book.tlds[term.k]) fail(def.name, 'Imported reference has no authenticated declaration: ' + printedKey(term.k), term);
  if (term.$ === 'Ctr' && (!book.ctrs[term.k] || book.ctrs[term.k]!.n !== term.x.length))
    fail(def.name, 'Native constructor field authentication failed: ' + printedKey(term.k), term);
  if (term.$ === 'All') return {...term, A: normalize(term.A, def, 'signature', true), B: normalize(term.B, def, 'signature', true)};
  // Structural copying preserves this typed AST's discriminant and field shape.
  const out = Object.fromEntries(Object.entries(term).map(([key, child]) => {
    if (key === 's') return [key, child];
    if (Array.isArray(child)) return [key, child.map(value => value && typeof value === 'object' && '$' in value ? normalize(value as B.LTerm, def, context, erased) : value)];
    if (child && typeof child === 'object' && '$' in child && !['None', 'Lone', 'Many'].includes(child.$)) return [key, normalize(child as B.LTerm, def, context, erased || (term.$ === 'Ann' && key === 'T'))];
    return [key, child];
  })) as B.LTerm;
  return out;
}
let authenticatedPatterns = 0;
function authenticatePattern(pattern: B.Patt, def: Definition): void {
  if (pattern.$ === 'PVar') return;
  const constructor = book.ctrs[pattern.k];
  if (!constructor || constructor.n !== pattern.x.length) fail(def.name, 'Unauthenticated native constructor pattern ' + printedKey(pattern.k));
  providers.add(pattern.k);
  authenticatedPatterns++;
  pattern.x.forEach(child => authenticatePattern(child, def));
}
function normalizeBody(node: B.Body, def: Definition): B.Body {
  if (node.$ === 'Local') node.k.forEach(pattern => authenticatePattern(pattern, def));
  else if (node.$ === 'Match') node.r.forEach(row => row.p.forEach(pattern => authenticatePattern(pattern, def)));
  if (node.$ !== 'Local' && node.$ !== 'Match') return normalize(node, def, 'terminal');
  if (node.$ === 'Local') return {...node, v: node.v.map(value => normalize(value, def, 'local', node.q.$ === 'None')), f: normalizeBody(node.f, def)};
  return {...node, e: node.e.map(value => normalize(value, def, 'match')), r: node.r.map(row => ({p: row.p, f: normalizeBody(row.f, def)}))};
}
const resultKinds: Record<string, string> = Object.create(null);
const requestParameterKinds: Record<string, {name: string; kind: 'Data' | 'Type'}[]> = Object.create(null);
for (const def of definitions) {
  def.parameters = def.parameters.map(parameter => [parameter[0], parameter[1], parameter[2], normalize(parameter[3], def, 'signature', true), parameter[4]]);
  def.result = normalize(def.result, def, 'signature', true); def.body = normalizeBody(def.body, def);
  if (paths.mode === 'checker') {
    let context = B.ctx_nil(), environment: B.Env = null;
    requestParameterKinds[def.name] = def.parameters.map((parameter, index) => {
      const domain = B.term_higher(parameter[3], environment);
      try {
        const inferred = B.term_infer(book, {t: domain, n: 0, def: def.name, qs: []}, domain, B.None(), context, index);
        const kind = B.term_wnf(book, inferred.ty);
        if (kind.$ !== 'Typ') fail(def.name, 'Request parameter lacks a concrete authenticated kind: ' + parameter[1], parameter[3]);
        const quantity = B.term_wnf(book, kind.g);
        if (quantity.$ !== 'Qua' || (quantity.q.$ !== 'Many' && quantity.q.$ !== 'Lone'))
          fail(def.name, 'Request parameter lacks a supported concrete kind: ' + parameter[1], parameter[3]);
        context = B.ctx_bind(context, index, parameter[0], parameter[1], domain);
        environment = B.list_set(environment, parameter[2], B.Var(parameter[1], index));
        return {name: parameter[1], kind: quantity.q.$ === 'Many' ? 'Data' as const : 'Type' as const};
      } catch (error) {
        const diagnostic = error && typeof error === 'object' && '$' in error && error.$ === 'Err'
          ? B.err_show(error as B.Err) : String(error);
        fail(def.name, 'Request parameter-kind authentication failed (' + parameter[1] + '): ' + diagnostic, parameter[3]);
      }
    });
  }
  if (freeBinderIds(def.result).length) fail(def.name, 'Unsupported dependent source result telescope');
  // Classify closed result kinds from real Book signatures. Data results may
  // initialize original reusable (+) bindings; affine Type results remain affine.
  try {
    const result = B.term_higher(def.result);
    const inferred = B.term_infer(book, {t: result, n: 0, def: def.name, qs: []}, result, B.None(), B.ctx_nil(), 0);
    const kind = B.term_wnf(book, inferred.ty);
    if (kind.$ !== 'Typ') fail(def.name, 'Source result lacks a concrete authenticated kind', def.result);
    const quantity = B.term_wnf(book, kind.g);
    if (quantity.$ !== 'Qua' || (quantity.q.$ !== 'Many' && quantity.q.$ !== 'Lone'))
      fail(def.name, 'Source result lacks a supported concrete kind: ' + showTerm(B.term_lower(kind), [], -1), def.result);
    resultKinds[def.name] = quantity.q.$ === 'Many' ? 'Data' : 'Type';
  } catch (error) {
    const diagnostic = error && typeof error === 'object' && '$' in error && error.$ === 'Err'
      ? B.err_show(error as B.Err) : String(error);
    fail(def.name, 'Result-kind authentication failed: ' + diagnostic, def.result);
  }
}
const allResultsData = definitions.every(def => resultKinds[def.name] === 'Data');
const resultKind = allResultsData ? 'Data' : 'Type';
const resultQuantity = (name: string): B.Quant => resultKinds[name] === 'Data' ? B.Many() : B.Lone();
const sourceEdges = new Map([...names].map(name => [name, new Set<string>()]));
for (const effect of effects) sourceEdges.get(effect.caller)!.add(effect.callee);
const publicRoots=paths.mode==='checker'?[paths.root,'inspect_checked']:entries?[...new Set(entries.flatMap(entry=>[entry.root,entry.libraryRoot]))]:[paths.root];
const reachable = new Set<string>(), pending = [...publicRoots];
while (pending.length) {
  const name = pending.pop()!;
  if (reachable.has(name)) continue;
  if (!sourceEdges.has(name)) throw Error('Native step entry is missing from exact source closure');
  reachable.add(name); pending.push(...sourceEdges.get(name)!);
}
if (paths.mode === 'checker' && reachable.size !== names.size) throw Error('Source contains definitions outside the authenticated public roots '+publicRoots.join(', ')+': ' + [...names].filter(name => !reachable.has(name)).join(', '));
// Direct values are deliberately limited to non-constructing projections and
// selectors with a live source argument. Returning a bound value or a nullary
// constructor cannot materialize a large constant or rebuild captured records.
// Locals and match scrutinees only alias bound values; source-call composition,
// constructor fields and zero-live-arity definitions retain established CPS.
// This is optimization eligibility, not a source-language restriction. In
// particular, acyclic computation alone is insufficient: native folding of
// composed value helpers can duplicate large constants and reconstructed values.
const pureNames = new Set<string>(), pureDefinitions: Definition[] = [];
function projectionTerm(term: B.LTerm, allowConstant = false): boolean {
  if (term.$ === 'Var') return true;
  if (term.$ === 'Ctr') return allowConstant && term.x.length === 0;
  if (term.$ === 'Lit') return allowConstant && (term.k === 'Nat' && term.v === 0 || term.k === 'String' && term.v === '');
  if (term.$ === 'Ann') return projectionTerm(term.x, allowConstant);
  return false;
}
function projectionBody(body: B.Body): boolean {
  if (body.$ !== 'Local' && body.$ !== 'Match') return projectionTerm(body, true);
  if (body.$ === 'Local') return body.v.every(term => projectionTerm(term)) && projectionBody(body.f);
  return body.e.every(term => projectionTerm(term)) && body.r.every(row => projectionBody(row.f));
}
for (const def of definitions) {
  if (def.parameters.some(parameter => parameter[0].$ !== 'None') && projectionBody(def.body)) {
    pureNames.add(def.name); pureDefinitions.push(def);
  }
}
// Compiler-private storage wrappers form bounded, nonrecursive native islands.
// They keep their checked signatures and evaluation order, but do not allocate a
// request/resume pair for every handle bit test, pool read or tuple adapter.
// General acyclic computation is still insufficient: admit only arena wrappers
// and the conservative bound predicate over admitted helpers/native storage and
// scalar operations, with no indirect calls, binders or recursion. Constructor
// skeletons, including live captures, stay bounded to 128 logical expanded nodes.
// The arena wrappers are pure projections over the arena's immutable-range
// tables: their transitive, nonrecursive helper closure is admitted when every
// source edge is already a direct helper. IR.arena_* are closed bit/range
// arithmetic on U32 values; they are evaluated directly like the existing
// Arena/U32/Nat native atoms.
function closedStorageSize(term: B.LTerm): number {
  if (term.$ === 'Var') return 0;
  if (term.$ === 'Lit') {
    if (term.k === 'Nat') return term.v + 1;
    // word_to_term is 32 WCon/Bool pairs plus WNil; U32/F32 add one wrapper.
    if (term.k !== 'String') return 66;
    let size = 1; // SNil; each code point adds SCon, Chr and its 66-node U32.
    for (const _ of term.v) {size += 68; if (size > 128) break;}
    return size;
  }
  let size = 1;
  for (const child of termChildren(term)) {size += closedStorageSize(child); if (size > 128) break;}
  return size;
}
function storageTerm(term: B.LTerm): boolean {
  if (term.$ === 'Var') return true;
  if (term.$ === 'Ann') return storageTerm(term.x);
  if (term.$ === 'Lit') return closedStorageSize(term) <= 128;
  if (term.$ === 'Ctr') {
    if (!term.x.every(storageTerm)) return false;
    return closedStorageSize(term) <= 128;
  }
  if (term.$ === 'App') {
    const [head, args] = B.term_unapply(term);
    return head.$ === 'Ref' && (pureNames.has(head.k)
      || /^(Arena|U32|Nat)\.|^IR\.arena_/.test(printedKey(head.k))) && args.every(storageTerm);
  }
  return false;
}
function storageBody(body: B.Body): boolean {
  if (body.$ !== 'Local' && body.$ !== 'Match') return storageTerm(body);
  if (body.$ === 'Local') return body.v.every(storageTerm) && storageBody(body.f);
  return body.e.every(storageTerm) && body.r.every(row => storageBody(row.f));
}
const storageNames = new Set<string>();
if (paths.mode === 'checker') {
  for (let changed = true; changed;) {
    changed = false;
    for (const def of definitions) {
      if (pureNames.has(def.name) || (!def.name.startsWith('arena_') && def.name !== 'core_bound_unaffected')
        || !def.parameters.some(parameter => parameter[0].$ !== 'None')
        || ![...sourceEdges.get(def.name)!].every(name => pureNames.has(name))
        || !storageBody(def.body)) continue;
      pureNames.add(def.name); pureDefinitions.push(def);
      storageNames.add(def.name); changed = true;
    }
  }
}
const signatures = new Map(definitions.map(def => [def.name, {parameters: def.parameters, result: def.result}]));
const reserved = new Set([...clean.matchAll(/\b[A-Za-z_]\w*\b/g)].map(match => match[0]));
function reserve(name: string): string {if (reserved.has(name)) throw Error('Generated name collision ' + name); reserved.add(name); return name;}
for (const name of [requestType, progressType, valueType, finishedType, pendingType, directType, boundType,
  resultFunction, stepFunction, rawStepFunction, chunkFunction, unboxFunction, startFunction,
  stackType, stackDoneType, stackMoreType, runType, runFinishedType, runStateType,
  castBoxFunction, popFunction, advanceFunction]) reserve(name);
for (const name of startNames) if (name !== startFunction) {
  if (reserved.has(name)) throw Error('Generated name collision ' + name);
  reserved.add(name);
}
const requestName = new Map(definitions.map(def => [def.name, reserve(requestType + '_' + def.name)]));
// Keep request datatypes and dispatch bodies bounded. A single thousands-row
// dependent match is expensive for both the source checker and native JS.
const requestGroupSize = 64;
const requestGroups = Array.from({length: Math.ceil(definitions.length / requestGroupSize)}, (_, index) => ({
  type: reserve(requestType + 'Group' + index),
  constructor: reserve(requestType + 'Group_' + index),
  result: reserve(resultFunction + '_group_' + index),
  step: reserve(stepFunction + '_group_' + index),
  definitions: definitions.slice(index * requestGroupSize, (index + 1) * requestGroupSize),
}));
const requestGroup = new Map(requestGroups.flatMap(group => group.definitions.map(def => [def.name, group] as const)));
function request(name: string, arguments_: B.LTerm[]): B.LTerm {
  return ctr(requestGroup.get(name)!.constructor, [ctr(requestName.get(name)!, arguments_)]);
}
const stepName = new Map(definitions.map(def => [def.name, reserve(prefix + '_body_' + def.name)]));
const pureName = new Map(pureDefinitions.map(def => [def.name, reserve(prefix + '_pure_' + def.name)]));
// The unused scheduling token is authentic Base False, emitted as a scalar.
// Keep the generic typed Direct ABI without allocating a Unit record per call.
const directBool = book.tlds.Bool;
if (!directBool || directBool.$ !== 'ADT' || directBool.n !== 0
  || directBool.c.length !== 2 || directBool.c.some(ctor => ctor.n !== 0)
  || !directBool.c.some(ctor => ctor.k === 'False')
  || !directBool.c.some(ctor => ctor.k === 'True')) throw Error('Authentic Base Bool required for Direct scheduling');
providers.add('Bool');
function directPureCalls(term: B.LTerm): B.LTerm {
  if (term.$ === 'Ref' && pureName.has(term.k)) return {...term, k: pureName.get(term.k)!};
  if (term.$ === 'App') return {...term, f: directPureCalls(term.f), x: directPureCalls(term.x)};
  if (term.$ === 'Ctr') return {...term, x: term.x.map(directPureCalls)};
  if (term.$ === 'Ann') return {...term, x: directPureCalls(term.x)};
  return term;
}
const ref = (k: string): B.LTerm => ({$: 'Ref', k});
const ctr = (k: string, x: B.LTerm[]): B.LTerm => ({$: 'Ctr', k, x});
const app = (k: string, xs: B.LTerm[]): B.LTerm => xs.reduce<B.LTerm>((f, x) => ({$: 'App', f, x}), ref(k));
const progress = (type: B.LTerm): B.LTerm => ({$: 'ADT', k: progressType, x: [type], r: []});
const boxedValue = (type: B.LTerm): B.LTerm => ({$: 'ADT', k: valueType, x: [type], r: []});
const finished = (value: B.LTerm): B.LTerm => ctr(finishedType, [ctr(valueType, [value])]);
const generated: {name: string; parameters: ParserParameter[]; result: B.LTerm; body: B.Body; owner: string; kind: string}[] = [];
let helperSerial = 0, syntheticId = 1000000, pendingCount = 0, lazyChoices = 0;
const ownerBindings = new Map<string, Map<number, Binding>>();
let activeOwner = '';
type SourceVar = Extract<B.LTerm, {$: 'Var'}>;
const fusedTailSites: {caller: string; callee: string}[] = [];
const directCallSites: {caller: string; callee: string}[] = [];
function delayedProgress(owner: Definition, target: Definition, values: B.LTerm[], resume: B.LTerm): B.LTerm {
  const witness = request(target.name, values);
  // Callable references obey the same native declaration DAG as ordinary
  // helpers. Self/future/backedge calls retain the typed request boundary.
  if (target.begin < owner.begin) {
    directCallSites.push({caller: owner.name, callee: target.name});
    const id = syntheticId++;
    const argumentsType: B.LTerm = {$: 'ADT', k: 'Bool', x: [], r: []};
    const invoke: B.LTerm = {$: 'Lam', k: 'direct_tick_' + id, i: id,
      q: B.Lone(), f: app(stepName.get(target.name)!, values)};
    return ctr(directType, [argumentsType, witness, ctr('False', []), invoke, resume]);
  }
  pendingCount++;
  return ctr(pendingType, [witness, resume]);
}
const singleConstructors = new Set(Object.values(book.tlds)
  .flatMap(tld => tld.$ === 'ADT' && tld.c.length === 1 ? [tld.c[0]!.k] : []));
const recordRoundtrips: string[] = [];
function recordRoundtrip(body: B.Body, types: LexicalTypes, owner: string): B.LTerm | undefined {
  if (body.$ !== 'Local' || body.q.$ !== 'Lone' || body.k.length !== 1 || body.v.length !== 1) return;
  const pattern = body.k[0]!;
  if (pattern.$ !== 'PCtr' || !singleConstructors.has(pattern.k)
    || pattern.x.some(field => field.$ !== 'PVar')) return;
  const aliases = new Map<number, number>();
  for (const field of pattern.x) if (field.$ === 'PVar') aliases.set(field.i, field.i);
  let tail = body.f;
  while (tail.$ === 'Local') {
    if (tail.q.$ !== 'Lone') return;
    const additions: [number, number][] = [];
    for (let i = 0; i < tail.k.length; i++) {
      const binder = tail.k[i]!, value = tail.v[i]!;
      if (binder.$ !== 'PVar' || value.$ !== 'Var' || !aliases.has(value.i)) return;
      additions.push([binder.i, aliases.get(value.i)!]);
    }
    for (const [id, original] of additions) aliases.set(id, original);
    tail = tail.f;
  }
  if (tail.$ === 'Match') return;
  const annotations: Extract<B.LTerm, {$: 'Ann'}>[] = [];
  while (tail.$ === 'Ann') {
    if (freeBinderIds(tail.T).some(id => aliases.has(id))) return;
    annotations.push(tail); tail = tail.x;
  }
  if (tail.$ !== 'Ctr' || tail.k !== pattern.k || tail.x.length !== pattern.x.length
    || tail.x.some((field, i) => field.$ !== 'Var'
      || aliases.get(field.i) !== (pattern.x[i] as Extract<B.Patt, {$: 'PVar'}>).i)) return;
  const environment = types.environmentAt(tail);
  for (const field of pattern.x) {
    if (field.$ !== 'PVar' || field.q.$ !== 'Many') continue;
    const type = environment.get(field.i)?.type;
    // Keep every promotion check: only authenticated closed Data may bypass
    // reconstruction. Dependent/unsupported fields retain their original match.
    if (!type || freeBinderIds(type).length) return;
    const higher = B.term_higher(type);
    const inferred = B.term_infer(book, {t: higher, n: 0, def: owner, qs: []},
      higher, B.None(), B.ctx_nil(), 0);
    const kind = B.term_wnf(book, inferred.ty);
    if (kind.$ !== 'Typ') return;
    const quantity = B.term_wnf(book, kind.g);
    if (quantity.$ !== 'Qua' || quantity.q.$ !== 'Many') return;
  }
  let result = body.v[0]!;
  for (let i = annotations.length - 1; i >= 0; i--) result = {...annotations[i]!, x: result};
  return result;
}
function foldRecordRoundtrips(body: B.Body, owner: string, types: LexicalTypes): B.Body {
  const expression = recordRoundtrip(body, types, owner);
  if (expression) {recordRoundtrips.push(owner); return expression;}
  if (body.$ === 'Local') {
    const f = foldRecordRoundtrips(body.f, owner, types);
    return f === body.f ? body : {...body, f};
  }
  if (body.$ === 'Match') {
    let rows: B.Match['r'] | undefined;
    for (let i = 0; i < body.r.length; i++) {
      const row = body.r[i]!, f = foldRecordRoundtrips(row.f, owner, types);
      if (f !== row.f) {rows ??= body.r.slice(); rows[i] = {...row, f};}
    }
    return rows ? {...body, r: rows} : body;
  }
  return body;
}
function tailProgress(target: string, values: B.LTerm[], returned: B.LTerm): B.LTerm {
  if (returned.$ === 'Ann') return {$: 'Ann',
    x: tailProgress(target, values, returned.x), T: progress(returned.T)};
  return app(target, values);
}
function finishedResult(body: B.Body): B.LTerm | undefined {
  if (body.$ !== 'Ctr' || body.k !== finishedType || body.x.length !== 1) return;
  const box = body.x[0]!;
  if (box.$ !== 'Ctr' || box.k !== valueType || box.x.length !== 1) return;
  return box.x[0]!;
}
function canFuseTail(owner: Definition, target: Definition, values: B.LTerm[], body: B.Body, value: SourceVar): boolean {
  // Strictly decreasing authenticated source order leaves the native helper
  // graph acyclic. Recursion/back edges retain the existing request protocol.
  // Projection-only arguments and a live variable prevent closed-value folding
  // from duplicating large constructor constants through native composition.
  let returned = finishedResult(body);
  if (!returned) return false;
  while (returned.$ === 'Ann') returned = returned.x;
  return target.begin < owner.begin && values.every(term => projectionTerm(term, true))
    && values.some((term, index) => target.parameters[index]![0].$ !== 'None' && term.$ === 'Var')
    && returned.$ === 'Var' && returned.i === value.i;
}
function variable(type: B.LTerm, scope: Map<number, Binding>, quantity: B.Quant = B.Lone()): SourceVar {
  const id = syntheticId++, name = 'step_value_' + id;
  const binding = {id, name, type, quantity};
  scope.set(id, binding); ownerBindings.get(activeOwner)!.set(id, binding);
  return {$: 'Var', k: name, i: id};
}
function bodyFree(body: B.Body): number[] {
  const ids = new Set<number>();
  function patternIds(pattern: B.Patt, bound: Set<number>) {if (pattern.$ === 'PVar') bound.add(pattern.i); else pattern.x.forEach(child => patternIds(child, bound));}
  function visit(node: B.Body, bound: Set<number>) {
    const terms = node.$ === 'Local' ? node.v : node.$ === 'Match' ? node.e : [node];
    terms.forEach(term => freeBinderIds(term).forEach(id => {if (!bound.has(id)) ids.add(id);}));
    if (node.$ === 'Local') {const inner = new Set(bound); node.k.forEach(pattern => patternIds(pattern, inner)); visit(node.f, inner);}
    else if (node.$ === 'Match') node.r.forEach(row => {const inner = new Set(bound); row.p.forEach(pattern => patternIds(pattern, inner)); visit(row.f, inner);});
  }
  visit(body, new Set()); return [...ids];
}
// Every match becomes a root match in a private, dependency-first helper. Its
// scrutinized binders come first; captures come after, hence remain visible in
// native constructor branches. This includes computed conditions and nested
// fields. Helpers call only earlier generated helpers, never source functions.
function factorHelper(body: B.Body, scope: Map<number, Binding>, result: B.LTerm, owner: string, first: number[], kind: string, stem: string, direct = false): B.LTerm {
  const ids = [...first, ...bodyFree(body).filter(id => !first.includes(id))];
  const parameters = ids.map<ParserParameter>(id => {
    const binding = scope.get(id);
    if (!binding) fail(owner, 'Missing lexical capture type for binder ' + id);
    return [binding.quantity, binding.name, binding.id, binding.type, {file: {str: source, ns: '', al: aliases}, beg: 0, end: 0}];
  });
  // Reordering dependent captures would alter telescope scope. The checker
  // closure currently uses concrete datatypes; reject a future dependent case.
  const available = new Set<number>();
  for (const parameter of parameters) {
    if (freeBinderIds(parameter[3]).some(id => !available.has(id))) fail(owner, 'Unsupported dependent match-capture telescope order');
    available.add(parameter[2]);
  }
  const name = reserve(prefix + '_' + stem + '_' + helperSerial++);
  generated.push({name, parameters, result: direct ? result : progress(result), body, owner, kind});
  return app(name, ids.map(id => B.Var(scope.get(id)!.name, id)));
}
function factorMatch(body: B.Match, scope: Map<number, Binding>, result: B.LTerm, owner: string, direct = false): B.Body {
  const first: number[] = [];
  for (const expression of body.e) {
    if (expression.$ !== 'Var') fail(owner, 'Generated match requires a typed binder, not a computed scrutinee', expression);
    if (first.includes(expression.i)) fail(owner, 'Repeated native match scrutinee', expression);
    first.push(expression.i);
  }
  return factorHelper(body, scope, result, owner, first, direct ? 'pure-ordered-match' : 'ordered-match', 'match', direct);
}
function factorContinuation(body: B.Body, scope: Map<number, Binding>, result: B.LTerm, owner: string): B.LTerm {
  if (body.$ !== 'Local' && body.$ !== 'Match') return body;
  return factorHelper(body, scope, result, owner, [], 'continuation', 'continuation');
}
// One shared parameter-match getter consumes the affine carrier. A single Let
// restores the authenticated source-result quantity, including reusable Data;
// existing continuation factoring keeps all matches on named helper parameters.
function boxedContinuation(body: B.Body, scope: Map<number, Binding>, value: SourceVar, result: B.LTerm, owner: string): B.LTerm {
  const continuation = factorContinuation(body, scope, result, owner);
  const binding = scope.get(value.i)!;
  const next = new Map(scope), box = variable(boxedValue(binding.type), next);
  const unboxed: B.LTerm = {$: 'Let', k: [value.k], i: [value.i], q: [binding.quantity],
    v: [app(unboxFunction, [binding.type, box])], f: continuation};
  return {$: 'Lam', k: box.k, i: box.i, q: B.Lone(), f: unboxed};
}
// Generate the pure value closure first, then retain every original typed
// request handler. Even externally requested pure definitions finish through
// their checked value helper; no special runtime dispatch or unchecked path.
for (const {def, direct} of [
  ...pureDefinitions.map(def => ({def, direct: true})),
  ...definitions.map(def => ({def, direct: false})),
]) {
  if (!direct && pureNames.has(def.name)) {
    generated.push({name: stepName.get(def.name)!, parameters: def.parameters, result: progress(def.result),
      body: finished(app(pureName.get(def.name)!, def.parameters.map(p => B.Var(p[1], p[2])))),
      owner: def.name, kind: 'source-body'});
    continue;
  }
  activeOwner = def.name;
  const bindings = new Map<number, Binding>(); ownerBindings.set(def.name, bindings);
  const types = new LexicalTypes(book, signatures);
  try {types.indexBody(def.body, def.parameters, def.result);} catch (error) {fail(def.name, 'Original lexical type indexing failed: ' + String(error));}
  const loweringBody = foldRecordRoundtrips(def.body, def.name, types);
  try {types.indexBody(loweringBody, def.parameters, def.result);} catch (error) {fail(def.name, 'Lexical type indexing failed: ' + String(error));}
  const rootScope = new Map<number, Binding>(def.parameters.map(p => [p[2], {id: p[2], name: p[1], quantity: p[0], type: p[3]}]));
  for (const [id, binding] of rootScope) bindings.set(id, binding);
  const scopeAt = (term: B.LTerm, scope: Map<number, Binding>) => {
    const result = new Map([...scope, ...types.environmentAt(term)]);
    for (const [id, binding] of result) bindings.set(id, binding);
    return result;
  };
  function effectful(term: B.LTerm): boolean {
    if (term.$ === 'Ref' && names.has(term.k) && !pureNames.has(term.k)) return true;
    if (term.$ === 'App') {const [head] = B.term_unapply(term); if (head.$ === 'Ref' && ((names.has(head.k) && !pureNames.has(head.k)) || head.k === 'Bool.pick')) return true;}
    return termChildren(term).some(effectful);
  }
  function typeOf(term: B.LTerm): B.LTerm {
    try {return types.typeOf(term);} catch (error) {fail(def.name, 'Missing semantic expression type: ' + String(error), term);}
  }
  function telescopeArguments(telescope: B.HTerm | undefined, args: B.LTerm[], scope: Map<number, Binding>) {
    let env: B.Env = null;
    for (const [id, binding] of scope) env = B.list_set(env, id, B.Var(binding.name, id));
    const quantities: B.Quant[] = [], domains: B.LTerm[] = [];
    for (const arg of args) {
      if (!telescope || telescope.$ !== 'All') fail(def.name, 'Authenticated argument telescope is incomplete', arg);
      quantities.push(telescope.q);
      const domain = B.term_lower(telescope.A, syntheticId);
      function reserveIds(node: B.LTerm) {
        if ('i' in node) for (const id of Array.isArray(node.i) ? node.i : [node.i]) syntheticId = Math.max(syntheticId, id + 1);
        termChildren(node).forEach(reserveIds);
      }
      reserveIds(domain); domains.push(domain);
      telescope = telescope.B(B.term_higher(arg, env));
    }
    return {quantities, domains};
  }
  type Continuation = (value: B.LTerm, scope: Map<number, Binding>) => B.Body;
  function sequence(terms: B.LTerm[], scope: Map<number, Binding>, quantities: B.Quant[], finish: (values: B.LTerm[], scope: Map<number, Binding>) => B.Body, domains: B.LTerm[] = [], index = 0, values: B.LTerm[] = []): B.Body {
    if (index === terms.length) return finish(values, scope);
    const term = terms[index]!;
    return lowerTerm(term, scope, (value, inner) => {
      // Preserve runtime evaluation order before requests. Erased arguments
      // stay as source expressions: they have no runtime evaluation to sequence.
      if (quantities[index]?.$ !== 'None' && terms.slice(index + 1).some(effectful) && !effectful(term)) {
        const next = new Map(inner), domain = domains[index] ?? typeOf(term), v = variable(domain, next, quantities[index] ?? B.Lone());
        return {$: 'Local', q: B.Lone(), k: [{$: 'PVar', k: v.k, i: v.i, q: quantities[index] ?? B.Lone()}], v: [{$: 'Ann', x: value, T: domain}], f: sequence(terms, next, quantities, finish, domains, index + 1, [...values, v])};
      }
      return sequence(terms, inner, quantities, finish, domains, index + 1, [...values, value]);
    }, domains[index]);
  }
  function lowerTerm(term: B.LTerm, input: Map<number, Binding>, k: Continuation, expected?: B.LTerm): B.Body {
    const scope = scopeAt(term, input);
    if (!effectful(term)) return k(directPureCalls(term), scope);
    if (term.$ === 'Ref' && names.has(term.k)) {
      const target = byName.get(term.k)!;
      if (target.parameters.length) fail(def.name, 'Unsaturated request escaped normalization', term);
      const next = new Map(scope), value = variable(target.result, next, resultQuantity(target.name));
      return delayedProgress(def, target, [], boxedContinuation(k(value, next), next, value, def.result, def.name));
    }
    if (term.$ === 'App') {
      const [head, args] = B.term_unapply(term);
      if (head.$ === 'Ref' && head.k === 'Bool.pick') {
        if (args.length !== 4 || effectful(args[0]!)) fail(def.name, 'Unsupported dependent/effectful Bool.pick type argument', term);
        lazyChoices++;
        return lowerTerm(args[1]!, scope, (condition, inner) => {
          const next = new Map(inner), flag = variable(ref('Bool'), next);
          const arms: B.Match = {$: 'Match', e: [flag], r: [
            {p: [{$: 'PCtr', k: 'False', x: []}], f: lowerTerm(args[3]!, next, k, args[0])},
            {p: [{$: 'PCtr', k: 'True', x: []}], f: lowerTerm(args[2]!, next, k, args[0])},
          ]};
          const branch = factorMatch(arms, next, def.result, def.name);
          return {$: 'Local', q: B.Lone(), k: [{$: 'PVar', k: flag.k, i: flag.i, q: B.Lone()}], v: [condition], f: branch};
        });
      }
      if (head.$ !== 'Ref') fail(def.name, 'Effect under non-first-order application head', head);
      const target = byName.get(head.k);
      const telescope = target ? B.term_higher(B.tele_bind(target.parameters, target.result)) : book.tlds[head.k]?.T;
      const {quantities, domains} = telescopeArguments(telescope, args, scope);
      return sequence(args, scope, quantities, (values, inner) => {
        if (!target || pureNames.has(target.name)) return k(app(target ? pureName.get(target.name)! : head.k, values), inner);
        const next = new Map(inner), value = variable(target.result, next, resultQuantity(target.name));
        const continuationBody = k(value, next);
        if (canFuseTail(def, target, values, continuationBody, value)) {
          fusedTailSites.push({caller: def.name, callee: target.name});
          return tailProgress(stepName.get(target.name)!, values, finishedResult(continuationBody)!);
        }
        return delayedProgress(def, target, values, boxedContinuation(continuationBody, next, value, def.result, def.name));
      }, domains);
    }
    if (term.$ === 'Ctr') {
      const declaration = Object.values(book.tlds).find(tld => tld.$ === 'ADT' && tld.c.some(field => field.k === term.k));
      if (declaration?.$ !== 'ADT') fail(def.name, 'Constructor lacks an authenticated datatype declaration', term);
      // Every field domain is propagated into recursive lowering, even when
      // this constructor itself needs no sequencing temporary. A nested field
      // can need one later, so its datatype parameters must stay authentic.
      // Pure/zero-field constructors already returned before this branch.
      const datatype = declaration.n ? expected ?? typeOf(term) : undefined;
      if (datatype && datatype.$ !== 'ADT') fail(def.name, 'Effectful constructor lacks an authenticated datatype instance', term);
      let telescope = book.ctrs[term.k]?.T;
      let datatypeEnv: B.Env = null;
      if (declaration.n) for (const [id, binding] of scope) datatypeEnv = B.list_set(datatypeEnv, id, B.Var(binding.name, id));
      for (let index = 0; index < declaration.n; index++) {
        if (!telescope || telescope.$ !== 'All' || datatype?.$ !== 'ADT' || !datatype.x[index])
          fail(def.name, 'Constructor datatype parameter telescope drift', term);
        telescope = telescope.B(B.term_higher(datatype.x[index]!, datatypeEnv));
      }
      const {quantities, domains} = telescopeArguments(telescope, term.x, scope);
      return sequence(term.x, scope, quantities, (values, inner) => k({...term, x: values}, inner), domains);
    }
    if (term.$ === 'Ann') {
      if (effectful(term.T)) fail(def.name, 'Checker computation in annotation type', term.T);
      return lowerTerm(term.x, scope, (value, inner) => k({...term, x: value}, inner), term.T);
    }
    fail(def.name, 'Unsupported effectful term ' + term.$, term);
  }
  function lowerBody(body: B.Body, input: Map<number, Binding>): B.Body {
    if (body.$ !== 'Local' && body.$ !== 'Match') return lowerTerm(body, input, value => direct ? value : finished(value), def.result);
    if (body.$ === 'Local') return sequence(body.v, input, body.v.map(() => body.q), (values, scope) => {
      const next = new Map(scope);
      const continuationTerm = body.f.$ === 'Local' ? body.f.v[0]! : body.f.$ === 'Match' ? body.f.e[0]! : body.f;
      for (const [id, binding] of types.environmentAt(continuationTerm)) next.set(id, binding);
      const annotated = values.map((value, index): B.LTerm => value.$ === 'Ctr'
        ? {$: 'Ann', x: value, T: typeOf(body.v[index]!)} : value);
      const tail = lowerBody(body.f, next);
      if (body.k.some((pattern, index) => pattern.$ !== 'PVar'
        && values[index]!.$ !== 'Var')) {
        // Native matches scrutinize parameters/fields, never a computed local.
        // A direct storage result therefore gets its own typed match helper,
        // exactly like the existing computed-condition match lowering.
        const declarations = values.map((value, index) => ({
          value, v: variable(typeOf(body.v[index]!), next, body.q),
        }));
        const matched = factorMatch({$: 'Match',
          e: declarations.map(({v}) => v), r: [{p: body.k, f: tail}]},
          next, def.result, def.name, direct);
        return declarations.reduceRight<B.Body>((f, {v, value}) => ({
          $: 'Local', q: body.q, k: [{$: 'PVar', k: v.k, i: v.i, q: body.q}],
          v: [{$: 'Ann', x: value, T: next.get(v.i)!.type}], f,
        }), matched);
      }
      return {...body, v: annotated, f: tail};
    });
    return sequence(body.e, input, body.e.map(() => B.Lone()), (values, scope) => {
      const next = new Map(scope), declarations: {v: SourceVar; value: B.LTerm}[] = [];
      const scrutinees = values.map((value, index) => {
        if (value.$ === 'Var') return value;
        const v = variable(typeOf(body.e[index]!), next); declarations.push({v, value}); return v;
      });
      const result = factorMatch({...body, e: scrutinees, r: body.r.map(row => ({p: row.p, f: lowerBody(row.f, next)}))}, next, def.result, def.name, direct);
      return declarations.reduceRight<B.Body>((f, {v, value}) => ({$: 'Local', q: B.Lone(), k: [{$: 'PVar', k: v.k, i: v.i, q: B.Lone()}], v: [{$: 'Ann', x: value, T: next.get(v.i)!.type}], f}), result);
    });
  }
  const body = lowerBody(loweringBody, rootScope);
  generated.push({name: direct ? pureName.get(def.name)! : stepName.get(def.name)!, parameters: def.parameters,
    result: direct ? def.result : progress(def.result), body, owner: def.name, kind: direct ? 'pure-source-body' : 'source-body'});
}
// Administrative quantities belong only to derived handlers, not canonical
// request/source telescopes. Live usage is sequential addition and branch max;
// erased arguments and type annotations contribute no runtime consumption.
const administrativeQuantities: object[] = [];
type Usage = Map<number, number>;
const generatedSignatures = new Map(generated.map(def => [def.name, def.parameters]));
const requestSignatures = new Map(definitions.map(def => [requestName.get(def.name)!, def.parameters] as const));
function sumUsage(...parts: Usage[]): Usage {
  const result: Usage = new Map();
  for (const part of parts) for (const [id, count] of part) result.set(id, (result.get(id) ?? 0) + count);
  return result;
}
function branchUsage(parts: Usage[]): Usage {
  const result: Usage = new Map();
  for (const part of parts) for (const [id, count] of part) result.set(id, Math.max(result.get(id) ?? 0, count));
  return result;
}
for (const def of generated) {
  const bindings = ownerBindings.get(def.owner)!;
  function grade(id: number, quantity: B.Quant, uses: Usage, context: string): B.Quant {
    const count = uses.get(id) ?? 0;
    if (quantity.$ !== 'Lone' || count <= 1) return quantity;
    const binding = bindings.get(id);
    if (!binding) fail(def.owner, 'Missing administrative binding type for ' + id);
    const type = binding.type;
    if (freeBinderIds(type).length) fail(def.owner, 'Unsupported dependent administrative binding type for ' + id, type);
    const higher = B.term_higher(type);
    const inferred = B.term_infer(book, {t: higher, n: 0, def: def.owner, qs: []}, higher, B.None(), B.ctx_nil(), 0);
    const kind = B.term_wnf(book, inferred.ty);
    const kindQuantity = kind.$ === 'Typ' ? B.term_wnf(book, kind.g) : undefined;
    if (kindQuantity?.$ !== 'Qua' || kindQuantity.q.$ !== 'Many')
      fail(def.owner, 'Duplicated administrative binder ' + id + ' is not authenticated Data (uses ' + count + ')', type);
    administrativeQuantities.push({handler: def.name, owner: def.owner, binder: id, sourceName: binding.name,
      context, original: quantity.$, administrative: 'Many', liveUses: count, authenticatedKind: 'Data',
      type: showTerm(type, [], -1)});
    return B.Many();
  }
  function quantities(key: string, constructor: boolean): B.Quant[] {
    if (constructor && key === directType) return [B.None(), B.None(), B.Lone(), B.Lone(), B.Lone()];
    if (!constructor && key === unboxFunction) return [B.None(), B.Lone()];
    const parameters = generatedSignatures.get(key) ?? requestSignatures.get(key);
    if (parameters) return parameters.map(parameter => parameter[0]);
    let telescope = constructor ? book.ctrs[key]?.T : book.tlds[key]?.T;
    if (constructor && telescope) {
      const datatype = Object.values(book.tlds).find(tld => tld.$ === 'ADT' && tld.c.some(ctr => ctr.k === key));
      if (datatype?.$ === 'ADT') for (let i = 0; i < datatype.n; i++) {
        if (telescope.$ !== 'All') fail(def.owner, 'Administrative constructor telescope drift: ' + printedKey(key));
        telescope = telescope.B(B.Var('_', -1));
      }
    }
    const result: B.Quant[] = [];
    while (telescope?.$ === 'All') {result.push(telescope.q); telescope = telescope.B(B.Var('_', -1));}
    return result;
  }
  function term(node: B.LTerm): {node: B.LTerm; uses: Usage} {
    if (node.$ === 'Var') return {node, uses: new Map([[node.i, 1]])};
    if (node.$ === 'Ann') {const value = term(node.x); return {node: {...node, x: value.node}, uses: value.uses};}
    if (node.$ === 'Lam') {
      const body = term(node.f), q = grade(node.i, node.q ?? B.Lone(), body.uses, 'lambda');
      body.uses.delete(node.i); return {node: {...node, f: body.node, q}, uses: body.uses};
    }
    if (node.$ === 'Let') {
      const body = term(node.f), q = node.q.map((quantity, i) => grade(node.i[i]!, quantity, body.uses, 'continuation-local'));
      node.i.forEach(id => body.uses.delete(id));
      const values = node.v.map((value, i) => node.q[i]?.$ === 'None' ? {node: value, uses: new Map<number, number>()} : term(value));
      return {node: {...node, q, v: values.map(value => value.node), f: body.node}, uses: sumUsage(...values.map(value => value.uses), body.uses)};
    }
    if (node.$ === 'App') {
      const [head, args] = B.term_unapply(node), qs = head.$ === 'Ref' ? quantities(head.k, false) : [];
      const values = args.map((value, i) => qs[i]?.$ === 'None' ? {node: value, uses: new Map<number, number>()} : term(value));
      const fn = term(head);
      return {node: values.reduce<B.LTerm>((f, value) => ({$: 'App', f, x: value.node, s: node.s}), fn.node), uses: sumUsage(fn.uses, ...values.map(value => value.uses))};
    }
    if (node.$ === 'Ctr') {
      const qs = quantities(node.k, true);
      const values = node.x.map((value, i) => qs[i]?.$ === 'None' ? {node: value, uses: new Map<number, number>()} : term(value));
      return {node: {...node, x: values.map(value => value.node)}, uses: sumUsage(...values.map(value => value.uses))};
    }
    if (node.$ === 'Ref' || node.$ === 'Lit' || node.$ === 'Typ' || node.$ === 'Qnt' || node.$ === 'Qua' || node.$ === 'Min' || node.$ === 'All' || node.$ === 'ADT' || node.$ === 'Eql' || node.$ === 'Rfl' || node.$ === 'Efq' || node.$ === 'Hol')
      return {node, uses: new Map()};
    fail(def.owner, 'Unsupported administrative term ' + node.$, node);
  }
  function gradePatterns(rows: B.Patt[], uses: Usage, erased = false): B.Patt[] {
    return rows.map(pattern => {
      if (pattern.$ === 'PCtr') return {...pattern, x: gradePatterns(pattern.x, uses, erased)};
      const q = erased ? pattern.q : grade(pattern.i, pattern.q, uses, 'pattern/local');
      uses.delete(pattern.i); return {...pattern, q};
    });
  }
  function body(node: B.Body): {node: B.Body; uses: Usage} {
    if (node.$ !== 'Local' && node.$ !== 'Match') return term(node);
    if (node.$ === 'Local') {
      const next = body(node.f), k = gradePatterns(node.k, next.uses, node.q.$ === 'None');
      const values = node.v.map(value => node.q.$ === 'None' ? {node: value, uses: new Map<number, number>()} : term(value));
      return {node: {...node, k, v: values.map(value => value.node), f: next.node}, uses: sumUsage(...values.map(value => value.uses), next.uses)};
    }
    const values = node.e.map(term), rows = node.r.map(row => {
      const next = body(row.f), p = gradePatterns(row.p, next.uses);
      return {p, f: next.node, uses: next.uses};
    });
    return {node: {...node, e: values.map(value => value.node), r: rows.map(({p, f}) => ({p, f}))},
      uses: sumUsage(...values.map(value => value.uses), branchUsage(rows.map(row => row.uses)))};
  }
  const result = body(def.body);
  def.parameters = def.parameters.map(parameter => [grade(parameter[2], parameter[0], result.uses, 'parameter'), parameter[1], parameter[2], parameter[3], parameter[4]]);
  def.body = result.node;
}
// A parameter-identical root match needs no forwarding declaration. Perform
// this only after quantity grading: a promoted helper must not silently widen
// its source handler's telescope. Types and binder identities are retained,
// not substituted or normalized, and singly referenced helpers alone disappear.
const rootMatchContractions: {owner: string; handler: string; helper: string}[] = [];
const helperUses = new Map<string, number>();
function countHelperUses(body: B.Body) {
  function term(node: B.LTerm) {
    if (node.$ === 'Ref') helperUses.set(node.k, (helperUses.get(node.k) ?? 0) + 1);
    termChildren(node).forEach(term);
  }
  if (body.$ === 'Local') {body.v.forEach(term); countHelperUses(body.f);}
  else if (body.$ === 'Match') {body.e.forEach(term); body.r.forEach(row => countHelperUses(row.f));}
  else term(body);
}
for (const def of generated) {
  countHelperUses(def.body);
  def.parameters.forEach(parameter => countHelperUses(parameter[3]));
  countHelperUses(def.result);
}
for (let index = 1; index < generated.length; index++) {
  const handler = generated[index]!, helper = generated[index - 1]!;
  if (handler.kind !== 'source-body' && handler.kind !== 'pure-source-body') continue;
  if (helper.kind !== 'ordered-match' && helper.kind !== 'pure-ordered-match') continue;
  if (helper.owner !== handler.owner || helper.body.$ !== 'Match' || helperUses.get(helper.name) !== 1
    || handler.body.$ !== 'App' || helper.parameters.length !== handler.parameters.length) continue;
  const [head, args] = B.term_unapply(handler.body);
  if (head.$ !== 'Ref' || head.k !== helper.name || args.length !== handler.parameters.length
    || !handler.parameters.every((parameter, at) => {
      const capture = helper.parameters[at]!, argument = args[at]!;
      return parameter[2] === capture[2] && parameter[3] === capture[3]
        && parameter[0].$ === capture[0].$ && argument.$ === 'Var' && argument.i === parameter[2];
    })) continue;
  const sameResult = helper.result === handler.result
    || helper.result.$ === 'ADT' && handler.result.$ === 'ADT'
      && helper.result.k === progressType && handler.result.k === progressType
      && helper.result.x[0] === handler.result.x[0];
  if (!sameResult) continue;
  handler.body = helper.body;
  rootMatchContractions.push({owner: handler.owner, handler: handler.name, helper: helper.name});
  generated.splice(index - 1, 1);
  index--;
}
const outputHeader = header.replace(/^import (\S+) as ([A-Za-z_]\w*)$/gm, (_, imported: string, alias: string) => {
  const target = posix.normalize(posix.join(dirname(paths.owned), imported));
  let relative = posix.relative(dirname(paths.output), target);
  if (!relative.startsWith('.')) relative = './' + relative;
  return 'import ' + relative + ' as ' + alias;
});
// A Checker request is Data only when every actual source parameter domain
// authenticates as Data. Affine domains require Type regardless of binder grade;
// Emitter and Template retain their conservative Type envelopes.
const requestKind = paths.mode === 'checker'
  && definitions.every(def => requestParameterKinds[def.name]!.every(parameter => parameter.kind === 'Data')) ? 'Data' : 'Type';
const chunks = [outputHeader, '\n# Bounded typed request groups; every source declaration retains its checked signature.\n'];
for (const group of requestGroups) {
  chunks.push('type ' + group.type + ' is ' + requestKind + ':\n');
  for (const def of group.definitions) {
    const rendered = renderBody(def.result, def.parameters, {book, showTerm});
    chunks.push('  ' + requestName.get(def.name)! + '{' + rendered.parameters + '}\n');
  }
  chunks.push('\n');
}
chunks.push('type ' + requestType + ' is ' + requestKind + ':\n');
for (const group of requestGroups) chunks.push('  ' + group.constructor + '{request: ' + group.type + '}\n');
for (const group of requestGroups) {
  chunks.push('\ndef ' + group.result + '(request: ' + group.type + ') -> ' + resultKind + ':\n  match request:\n');
  for (const def of group.definitions) chunks.push('    case ' + requestName.get(def.name)! + '{' + def.parameters.map(() => '_').join(', ') + '}: ' + def.resultSource + '\n');
}
chunks.push('\ndef ' + resultFunction + '(request: ' + requestType + ') -> ' + resultKind + ':\n  match request:\n');
for (const group of requestGroups) chunks.push('    case ' + group.constructor + '{inner}: ' + group.result + '(inner)\n');
const resumeType = '(@box: ' + valueType + '<' + resultFunction + '(request)> -> ' + progressType + '<A>)';
chunks.push('\ntype ' + valueType + '<-A: Type> is Type:\n  ' + valueType + '{value: A}\n');
chunks.push('\ntype ' + progressType + '<-A: Type> is Type:\n  ' + finishedType + '{box: ' + valueType + '<A>}\n  ' + pendingType + '{request: ' + requestType + ', resume: ' + resumeType + '}\n  ' + directType + '{-R: Type, -request: ' + requestType + ', arguments: R, invoke: (@arguments: R -> ' + progressType + '<' + resultFunction + '(request)>), resume: ' + resumeType + '}\n  ' + boundType + '{-B: Type, inner: ' + progressType + '<B>, resume: (@box: ' + valueType + '<B> -> ' + progressType + '<A>)}\n\n');
chunks.push(`
type ${stackType}<-A: Type, -R: Type> is Type:
  ${stackDoneType}{equation: {A == R : Type}}
  ${stackMoreType}{-B: Type, resume: (@box: ${valueType}<A> -> ${progressType}<B>), rest: ${stackType}<B, R>}

type ${runType}<-R: Type> is Type:
  ${runFinishedType}{box: ${valueType}<R>}
  ${runStateType}{-A: Type, progress: ${progressType}<A>, stack: ${stackType}<A, R>}

def ${castBoxFunction}(-A: Type, -R: Type, equation: {A == R : Type}, box: ${valueType}<A>) -> ${valueType}<R>:
  %equation : ${valueType}<_>
  box

`);
chunks.push('def ' + unboxFunction + '(-A: Type, box: ' + valueType + '<A>) -> A:\n  match box:\n    case ' + valueType + '{value}: value\n\n');
const generatedNames = new Set(generated.map(def => def.name)), positions = new Map(generated.map((def, index) => [def.name, index]));
const generatedEdges: {from: string; to: string}[] = [];
for (const [index, def] of generated.entries()) {
  function inspect(term: B.LTerm) {
    if (term.$ === 'Ref') {
      if (names.has(term.k)) fail(def.owner, 'Residual checker call/reference ' + term.k, term);
      if (generatedNames.has(term.k)) {generatedEdges.push({from: def.name, to: term.k}); if (positions.get(term.k)! >= index) fail(def.owner, 'Recursive or forward private helper reference ' + term.k);}
    }
    termChildren(term).forEach(inspect);
  }
  function inspectBody(body: B.Body) {
    (body.$ === 'Local' ? body.v : body.$ === 'Match' ? body.e : [body]).forEach(inspect);
    if (body.$ === 'Local') inspectBody(body.f); else if (body.$ === 'Match') body.r.forEach(row => inspectBody(row.f));
  }
  inspectBody(def.body);
  def.parameters.forEach(parameter => inspect(parameter[3]));
  inspect(def.result);
  const rendered = renderBody(def.body, def.parameters, {book, showTerm});
  chunks.push('def ' + def.name + '(' + rendered.parameters + ') -> ' + rendered.renderTerm(def.result) + ':\n' + rendered.body + '\n\n');
}
for (const group of requestGroups) {
  chunks.push('def ' + group.step + '(request: ' + group.type + ') -> ' + progressType + '<' + group.result + '(request)>:\n  match request:\n');
  for (const def of group.definitions) {
    const fields = def.parameters.map((_, index) => 'arg_' + index);
    chunks.push('    case ' + requestName.get(def.name)! + '{' + fields.join(', ') + '}: ' + stepName.get(def.name)! + '(' + fields.join(', ') + ')\n');
  }
  chunks.push('\n');
}
chunks.push('def ' + rawStepFunction + '(request: ' + requestType + ') -> ' + progressType + '<' + resultFunction + '(request)>:\n  match request:\n');
for (const group of requestGroups) chunks.push('    case ' + group.constructor + '{inner}: ' + group.step + '(inner)\n');
// Each transition consumes the current progress and heterogeneous native stack
// once. Source resume/invoke closures are retained without Bound association.
chunks.push(`
def ${popFunction}(-A: Type, -R: Type, stack: ${stackType}<A, R>, box: ${valueType}<A>) -> ${runType}<R>:
  match stack:
    case ${stackDoneType}{equation}: ${runFinishedType}{${castBoxFunction}(A, R, equation, box)}
    case ${stackMoreType}{B, resume, rest}: ${runStateType}{B, resume(box), rest}

def ${advanceFunction}(-A: Type, -R: Type, progress: ${progressType}<A>, stack: ${stackType}<A, R>) -> ${runType}<R>:
  match progress:
    case ${finishedType}{box}: ${popFunction}(A, R, stack, box)
    case ${pendingType}{request, resume}:
      ${runStateType}{${resultFunction}(request), ${rawStepFunction}(request), ${stackMoreType}{A, resume, stack}}
    case ${directType}{T, request, arguments, invoke, resume}:
      ${runStateType}{${resultFunction}(request), invoke(arguments), ${stackMoreType}{A, resume, stack}}
    case ${boundType}{B, inner, resume}:
      ${runStateType}{B, inner, ${stackMoreType}{A, resume, stack}}

def ${chunkFunction}(-R: Type, fuel: Nat, run: ${runType}<R>) -> ${runType}<R>:
  match fuel run:
    case 0n state: state
    case 1n+rest ${runFinishedType}{box}: ${runFinishedType}{box}
    case 1n+rest ${runStateType}{A, progress, stack}:
      ${chunkFunction}(R, rest, ${advanceFunction}(A, R, progress, stack))

def ${stepFunction}(-R: Type, run: ${runType}<R>) -> ${runType}<R>:
  ${chunkFunction}(R, ${nativeChunkQuantum}n, run)
`);
const emitterFiles = 'files: List<&2, BIR.SourceFile>';
const startInput = 'modules: List<&2, Loader.LoadedModule>';
const startArguments = paths.mode === 'checker' ? 'modules, Nil{}' : 'modules';
function typedStart(name:string, root:string, parameters:string, arguments_:string, result:string){
 const group=requestGroup.get(root),request=requestName.get(root);
 if(!group||!request)throw Error('Missing typed public root '+root);
 return '\ndef '+name+'('+parameters+') -> '+runType+'<'+result+'>:\n  '+chunkFunction+'('+result+', '+nativeChunkQuantum+'n, '+runStateType+'{'+result+', '+pendingType+'{'+group.constructor+'{'+request+'{'+arguments_+'}}, box => '+finishedType+'{box}}, '+stackDoneType+'{{==}}})\n';
}
if (entries && paths.mode !== 'checker') {
  for (const entry of entries) {
    if (entry.mode === 'emitter') {
      chunks.push(typedStart('emitter_start', entry.root, 'program: Checked.CheckedProgram, ' + emitterFiles, 'program, files', paths.result));
      chunks.push(typedStart('emitter_library_start', entry.libraryRoot, 'program: Checked.CheckedProgram, exports: List<&2, String>, ' + emitterFiles, 'program, exports, files', paths.result));
    } else {
      chunks.push(typedStart('cemit_start', entry.root, 'program: Checked.CheckedProgram, runtime: String, ' + emitterFiles, 'program, runtime, files', paths.result));
      chunks.push(typedStart('cemit_library_start', entry.libraryRoot, 'program: Checked.CheckedProgram, exports: List<&2, String>, runtime: String, ' + emitterFiles, 'program, exports, runtime, files', paths.result));
    }
  }
} else {
  chunks.push(typedStart(startFunction, paths.root, startInput, startArguments, paths.result));
  if (paths.mode === 'checker') chunks.push(typedStart('checker_inspect_start', 'inspect_checked', 'program: Checked.CheckedProgram', 'program', 'Checked.Inspection'));
}
const output = chunks.join('');
const alias = paths.componentAlias ?? (paths.mode === 'checker' ? 'CheckerCore' : paths.mode === 'emitter' ? 'JSEmit' : 'Template');
const outputImport = './' + posix.basename(paths.output);
const resultType=paths.result.includes('.')?paths.result:alias+'.'+paths.result;
let wrappers: string;
if (entries && paths.mode !== 'checker') {
  // One component exposes every target entry path of the shared composition.
  // Every wrapper keeps the established public name and arity; both targets
  // use the same Run engine, so no per-target scheduler is visible here.
  const run = alias + '.' + runType;
  const rows: string[] = [];
  for (const entry of entries) {
    if (entry.mode === 'emitter') {
      rows.push('def emit_modules_start(program: Checked.CheckedProgram, ' + emitterFiles + ') -> ' + run + '<' + resultType + '>:\n  ' + alias + '.emitter_start(program, files)');
      rows.push('def emit_library_start(program: Checked.CheckedProgram, exports: List<&2, String>, ' + emitterFiles + ') -> ' + run + '<' + resultType + '>:\n  ' + alias + '.emitter_library_start(program, exports, files)');
      rows.push('def emitter_step(-R: Type, run: ' + run + '<R>) -> ' + run + '<R>:\n  ' + alias + '.emitter_step(R, run)');
    } else {
      rows.push('def emit_c_modules_start(program: Checked.CheckedProgram, runtime: String, ' + emitterFiles + ') -> ' + run + '<' + resultType + '>:\n  ' + alias + '.cemit_start(program, runtime, files)');
      rows.push('def emit_c_library_start(program: Checked.CheckedProgram, exports: List<&2, String>, runtime: String, ' + emitterFiles + ') -> ' + run + '<' + resultType + '>:\n  ' + alias + '.cemit_library_start(program, exports, runtime, files)');
      rows.push('def c_emitter_step(-R: Type, run: ' + run + '<R>) -> ' + run + '<R>:\n  ' + alias + '.emitter_step(R, run)');
    }
  }
  wrappers = rows.join('\n\n');
} else {
  const wrapper = paths.mode === 'checker' ? 'check_expanded_start' : paths.mode === 'template' ? 'expand_modules_start' : '';
  const startCall = paths.mode === 'checker' ? 'modules' : 'modules';
  if (!wrapper) throw Error('Unsupported step component mode ' + paths.mode);
  wrappers = 'def ' + wrapper + '('+startInput+') -> ' + alias + '.' + runType + '<' + resultType + '>:\n  ' + alias + '.' + startFunction + '('+startCall+')\n\n'
   + (paths.mode==='checker'?'def inspect_checked_start(program: Checked.CheckedProgram) -> CheckerCore.CheckerRun<Checked.Inspection>:\n  CheckerCore.checker_inspect_start(program)\n\n':'')
   + 'def ' + stepFunction + '(-R: Type, run: ' + alias + '.' + runType + '<R>) -> ' + alias + '.' + runType + '<R>:\n  ' + alias + '.' + stepFunction + '(R, run)';
}
const loaderImport=header.match(/^import (\S+) as Loader$/m)?.[0];
const birImport=header.match(/^import (\S+) as BIR$/m)?.[0];
if(paths.mode==='emitter'&&!birImport)throw Error('Emitter component needs the authenticated backend_ir import for BIR.SourceFile');
const checkedImport=header.match(/^import (\S+) as Checked$/m)?.[0];
if((paths.mode==='checker'||paths.mode==='template')&&!loaderImport||paths.mode==='emitter'&&!checkedImport)throw Error('Typed step component has no authenticated boundary import');
const component = [loaderImport,checkedImport,birImport].filter(Boolean).join('\n')+'\nimport ' + outputImport + ' as ' + alias + '\n\n' + wrappers + '\n';
let driver: string | undefined;
if (paths.driver) {
if (paths.mode !== 'checker' || !paths.ownedDriver) throw Error('Only the checker component derives a driver');
const driverSource = inputs.get(paths.ownedDriver)!;
const oldImport = 'import ./checker_core_owned_v1.bend as CheckerCore';
const oldWrapper = 'def check_expanded(modules: List<&2, Loader.LoadedModule>) -> Checked.CheckResult:\n  CheckerCore.check_modules(modules, Nil{})';
if (driverSource.split(oldImport).length !== 2 || driverSource.split(oldWrapper).length !== 2) throw Error('Derived driver wrapper anchor drift');
driver = driverSource.replace(oldImport, 'import ' + outputImport + ' as ' + alias).replace(oldWrapper, wrappers);
}
for (const [path, text] of inputs) if (readFileSync(path, 'utf8') !== text || realpathSync(path) !== generationInputRealpaths[path]) throw Error('Input changed during generation: ' + path);
writeChanged(paths.output, output); writeChanged(paths.component, component);
if (paths.driver && driver !== undefined) writeChanged(paths.driver, driver);
const manifest = {
  version: 1, algorithm: 'raw-AST typed boxed-continuation CPS with bounded dependent request groups, dependency-first ordered match, projection values, bounded nonrecursive storage islands and structurally recursive native heterogeneous-stack chunks',
  generationConfig, generationEnvironment, generationInputRealpaths,
  nativeTerminationClaim: 'Generated source handlers and continuation helpers form an acyclic declaration graph. Only the native chunk scheduler is self-recursive, structurally decreasing an operational Nat on every RunState transition. Zero returns the remaining Run unchanged; RunFinished returns directly. Native push/pop transfers affine progress, resume and stack once, never reassociates Bound and never allocates composition closures. This does not alter canonical semantic fuel or claim termination of the complete host-driven computation.',
  progressABI: 'typed-native-stack-v57t',
  boxedTransport: {
    type: valueType, constructor: valueType, kind: 'Type', parameter: {name: 'A', kind: 'Type', quantity: 'None'},
    valueField: 'value', finishedField: 'box', resumeQuantity: 'Lone',
    resumeDomain: valueType + '<' + resultFunction + '(request)>',
    unboxFunction, unboxCallsPerResume: 1, unboxGetterCount: 1,
    unboxing: 'One generic named parameter-match getter consumes the carrier; a single Let restores each authenticated source result quantity: Many for Data, Lone for affine Type; existing continuation helpers retain named parameter matches; no computed/local native matches or unsafe casts',
  },
  nativeChunk: {
    function: chunkFunction, rawStep: rawStepFunction, publicStep: stepFunction, start: startFunction,
    quantum: nativeChunkQuantum, fuelType: 'Nat', recursion: 'structural Nat',
    zeroFuel: 'return remaining Run unchanged', semanticFuelChanged: false,
    boundConstructor: boundType, boundFields: ['inner', 'resume'], boundErasedType: 'B',
    pendingDispatch: rawStepFunction, directDispatch: 'source invoke(arguments)',
    finishedTransport: 'native stack pop passes whole box to source resume; StackDone consumes checked equality through Value<_> and returns RunFinished',
    runType, runFinishedConstructor: runFinishedType, runStateConstructor: runStateType,
    stackType, stackDoneConstructor: stackDoneType, stackMoreConstructor: stackMoreType,
    castBoxFunction, popFunction, advanceFunction,
    stackOwnership: 'Affine heterogeneous native LIFO; no host stack, no Bound reassociation, no Compose nodes, no per-site constructors',
    sourceResumeClosuresUnchanged: true, directInvokeUnchanged: true,
    publicStepType: '-R: Type, Run<R> -> Run<R>', exportedResume: false,
    selfRecursiveFunctions: [chunkFunction],
  },
  ffi: false, source: paths.owned, sourceSha256: sha(ownedSource), canonical: paths.canonical, canonicalSha256: sha(canonical),
  loweringSourceSha256: sha(source), loweringSourcePolicy: composition
    ? 'Binding-aware AST composition of every declaration in the explicit canonical provider closure, under the owned native-provider header; exact canonical source/declaration hashes and composed hashes are separate, with complete symbol ownership. Typed CPS factors matches once.'
    : 'Original authenticated canonical declaration blocks under the owned native-provider header; computed and nested matches factored once by typed CPS, not pre-expanded into source requests.',
  canonicalComposition: composition?.proof,
  sourceHeaderSha256: sha(header), derivedHeaderSha256: sha(outputHeader),
  sourceTypeDeclarations: [...mask(header).matchAll(/^type ([A-Za-z_]\w*)/gm)].map(match => {
    const name = match[1]!, declaration = book.tlds[name];
    if (declaration?.$ !== 'ADT') throw Error('Missing source datatype provider ' + name);
    return {name, parameters: declaration.n, constructors: declaration.c.map(ctr => ctr.k)};
  }),
  authenticatedBookProviders: [...providers].sort().map(key => {
    const declaration = book.tlds[key] ?? book.ctrs[key]!;
    return {name: printedKey(key), kind: 'k' in declaration ? 'Ctr' : declaration.$, signature: showTerm(B.term_lower(declaration.T), [], -1)};
  }),
  authenticatedResultKinds: resultKinds, resumeQuantity: 'Lone', unboxedResultQuantity: 'exact source-result kind', resultFunctionKind: resultKind, requestKind,
  authenticatedRequestParameterKinds: requestParameterKinds,
  requestGroupSize, requestGroups: requestGroups.map(group => ({type: group.type, constructor: group.constructor, result: group.result, step: group.step, definitions: group.definitions.map(def => def.name)})),
  administrativeQuantities, administrativeQuantityPolicy: 'Live-use-directed Many promotion only for authenticated Data; canonical request quantities and erased binders unchanged',
  exactCanonicalCoverage: true, definitionCount: definitions.length, excludedDefinitions: [],
  canonicalCoverage: [...canonicalNames].sort(), nativeMatchNormalizationOwners: componentProof.owners,
  normalizedSourceDeclarationHashes: componentProof.declarationHashes,
  sourceClosureRoot: paths.root, publicRoots, reachableDefinitions: [...reachable].sort(), ownedManifest: paths.ownedManifest,
  reachableRootSubset: [...reachable].sort(), allCoverage: [...names].sort(),
  outsideRootDefinitions: [...names].filter(name => !reachable.has(name)).sort(), omittedDefinitions: [],
  coverage: definitions.map(def => ({name: def.name, request: requestName.get(def.name), requestEnvelope: requestGroup.get(def.name)!.constructor, stepBody: stepName.get(def.name), pureBody: pureName.get(def.name), sourceSha256: sha(def.block), begin: def.begin, end: def.end, result: def.resultSource,
    signature: 'def ' + def.name + '(' + renderBody(def.result, def.parameters, {book, showTerm}).parameters + ') -> ' + def.resultSource})),
  callEffects: effects.map(effect => ({...effect, lowering: pureNames.has(effect.callee) ? 'direct-pure' : 'pending-or-acyclic-direct-or-tail'})),
  sourceCallCount: effects.length, pendingSiteCount: pendingCount, lazyBoolPickCount: lazyChoices,
  directPureSourceCallCount: effects.filter(effect => pureNames.has(effect.callee)).length,
  pendingSourceCallCount: effects.filter(effect => !pureNames.has(effect.callee)).length - fusedTailSites.length - directCallSites.length,
  fusedTailSourceCallCount: fusedTailSites.length,
  directSourceCallCount: directCallSites.length,
  directInvocation: {
    policy: 'Typed source closure only when target precedes owner in authenticated source order; erased request witness preserves exact result type; affine boxed resume uses one generic parameter-match getter and one quantity-preserving Let; live arguments transferred once into the affine closure; all public request handlers retained; future/self/backedge calls remain pending',
    constructor: directType, arguments: 'Authentic Base False{}; unused scalar affine callback token; five-field Direct with boxed resume',
    sites: directCallSites, invokers: [], argumentRecords: [], erasedRequestWitnessQuantity: 'None',
  },
  tailCallFusion: {
    policy: 'Identity Finished{Value{value}} continuation only; target precedes owner in authenticated source order; projection-only arguments with a live variable; typed target Progress and all request handlers retained; cycles and closed computations remain pending',
    sites: fusedTailSites,
    recordRoundtrips,
  },
  rootMatchContractions,
  pureCallClassification: {
    policy: 'Live source argument required. Projections do not construct values or call functions. Checker arena wrappers and core_bound_unaffected may compose admitted helpers with native Arena/U32/Nat and IR.arena_* scalar range/bit calls and bounded constructors, in dependency order; this admits the nonrecursive arena view/accessor closure but no recursion, indirect calls or function binders. All other definitions retain CPS',
    definitions: pureDefinitions.map(def => ({name: def.name, helper: pureName.get(def.name), resultKind: resultKinds[def.name],
      classification: def.name === 'core_bound_unaffected' ? 'bounded-native-bound-predicate' : storageNames.has(def.name) ? 'bounded-native-storage' : 'nonconstructing-projection',
      dependencies: [...sourceEdges.get(def.name)!], signatureQuantities: def.parameters.map(parameter => parameter[0].$),
      liveParameterCount: def.parameters.filter(parameter => parameter[0].$ !== 'None').length})),
    admissionOrder: pureDefinitions.map(def => def.name),
  },
  syntaxNormalizations: normalizations, authenticatedConstructorPatterns: authenticatedPatterns,
  privateHelpers: generated.filter(def => def.kind !== 'source-body').map(def => ({name: def.name, owner: def.owner, kind: def.kind})),
  generatedHelperEdges: generatedEdges, residualSourceCalls: 0, residualCheckerCalls: 0, recursiveHelpers: 1, generatedPrivateRecursiveHelpers: 0,
  protectedUnchangedHashes: Object.fromEntries(inputPaths.map(path => [path, sha(inputs.get(path)!)])),
  outputs: Object.fromEntries([[paths.output, output], [paths.component, component],
    ...(paths.driver && driver !== undefined ? [[paths.driver, driver]] : [])].map(([path, text]) => [path!, sha(text!)])),
  validation: {sourceGenerationOnly: true, nativeBuildRun: false, testsRun: false},
};
const authenticatedManifest = {...manifest, generationManifestSha256: sha(JSON.stringify(manifest))};
writeChanged(paths.manifest, JSON.stringify(authenticatedManifest, null, 2) + '\n');
console.log(JSON.stringify({source: paths.output, definitions: definitions.length, sourceCalls: effects.length, pendingSites: pendingCount, lazyChoices, helpers: generated.length, manifest: paths.manifest, reused: false}));
return authenticatedManifest;
}
if (import.meta.main) await generateNativeSteps(checkerStepConfig);
