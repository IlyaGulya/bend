import {createHash} from 'node:crypto';
import {existsSync, lstatSync, readFileSync, readdirSync, realpathSync, unlinkSync, writeFileSync} from 'node:fs';
import {dirname, isAbsolute, relative, resolve, sep} from 'node:path';
import {sourceOracle, type RawDeclaration, type SourceOracleResult} from './bootstrap_source_oracle.ts';
import {nativeSourceClosure} from './native_match_source.ts';

/** Source-only extraction: no checker, evaluator, normalizationBook or wrappers.
 * Module paths retain original universe-relative names in separate candidate trees.
 * Selection is preregistered source shape, never measured variant response. */
export type TailPlan = {
  schemaVersion: 1;
  sourceUniverse: {directory: string; files: {path: string; sha256: string}[]};
  observerStage0: {file: string; sha256: string};
  modules: {
    id: string;
    candidate: 'emitter-arity50' | 'parser-depth' | 'parser-feedback' | 'emitter-arity20';
    source: string;
    destinationDirectory: string;
    destination: string;
    roots: string[];
    rootCriterion?: {kind: 'parameter-arity-at-least'; minimum: 20; expectedCount: 30};
    omitImports: {alias: string; path: string}[];
  }[];
};
type ModulePlan = TailPlan['modules'][number];
type Issue = {code: string; detail: string; owner?: string};
type SpanRecord = {beginUTF16: number; endUTF16: number; beginByte: number; endByte: number; sliceSHA256: string};
type Reference = {key: string; owner: string; optional: boolean};
type ModuleReport = {
  id: string; candidate: ModulePlan['candidate']; source: string; destination: string;
  sourceDirectory: string; destinationDirectory: string; originalRelativePathPreserved: true;
  originalSHA256: string; status: 'complete' | 'inconclusive'; roots: string[];
  rootCriterion?: ModulePlan['rootCriterion']; issues: Issue[];
  selectedDefinitions: {key: string; kind: string; arity: number | null; reason: string[];
    original: SpanRecord; prefix: SpanRecord; emitted: SpanRecord}[];
  droppedFunctions: {key: string; original: SpanRecord}[];
  originalImports: {alias: string; path: string; namespace: string; resolved: string; original: SpanRecord}[];
  omittedImports: {alias: string; path: string; proof: 'no-selected-reference-to-module-and-all-external-owners-retained'}[];
  externalReferences: {key: string; owners: string[]; definitions: {source: string; key: string}[]; referencedBy: string[]; retainedVia: string[]}[];
  unresolvedExternalRefs: {key: string; referencedBy: string[]}[];
  derivedSignatureCoverage: {key: string; kind: 'constructor' | 'law-completion'; basis: string}[];
  header: SpanRecord; outputSHA256?: string; outputBytes?: number;
};
const sha = (data: string | Uint8Array) => createHash('sha256').update(data).digest('hex');
function requireThat(condition: unknown, message: string): asserts condition {
  if (!condition) throw Error(message);
}
function plain(value: unknown): value is Record<string, unknown> {
  return !!value && typeof value === 'object' && !Array.isArray(value);
}
function keys(value: Record<string, unknown>, allowed: string[], label: string): void {
  requireThat(Object.keys(value).every(key => allowed.includes(key)), `Unknown ${label} field`);
}
function text(value: unknown): value is string { return typeof value === 'string' && value.length > 0; }
function digest(value: unknown): value is string { return typeof value === 'string' && /^[a-f0-9]{64}$/.test(value); }
function validatePlan(value: unknown): asserts value is TailPlan {
  requireThat(plain(value), 'Plan must be an object');
  keys(value, ['schemaVersion', 'sourceUniverse', 'observerStage0', 'modules'], 'plan');
  requireThat(value.schemaVersion === 1 && plain(value.sourceUniverse) && plain(value.observerStage0), 'Invalid plan version/universe/observer');
  const universe = value.sourceUniverse, observer = value.observerStage0;
  keys(universe, ['directory', 'files'], 'universe'); keys(observer, ['file', 'sha256'], 'observer');
  requireThat(text(universe.directory) && Array.isArray(universe.files) && universe.files.length > 0, 'Missing universe manifest');
  for (const entry of universe.files) {
    requireThat(plain(entry), 'Invalid manifest entry'); keys(entry, ['path', 'sha256'], 'manifest');
    requireThat(text(entry.path) && digest(entry.sha256), 'Invalid manifest path/hash');
  }
  requireThat(text(observer.file) && digest(observer.sha256), 'Invalid observer file/hash');
  requireThat(Array.isArray(value.modules) && value.modules.length > 0, 'Missing modules');
  const candidates = new Set<string>(), ids = new Set<string>();
  for (const mod of value.modules) {
    requireThat(plain(mod), 'Invalid module');
    keys(mod, ['id', 'candidate', 'source', 'destinationDirectory', 'destination', 'roots', 'rootCriterion', 'omitImports'], 'module');
    requireThat(text(mod.id) && !ids.has(mod.id), 'Duplicate/invalid module id'); ids.add(mod.id);
    requireThat(text(mod.candidate) && ['emitter-arity50', 'parser-depth', 'parser-feedback', 'emitter-arity20'].includes(mod.candidate), 'Unknown candidate');
    candidates.add(mod.candidate);
    requireThat(text(mod.source) && text(mod.destinationDirectory) && mod.destination === mod.source && Array.isArray(mod.roots) && mod.roots.every(text), 'Source/destination must retain the same original relative path');
    requireThat(new Set(mod.roots).size === mod.roots.length, 'Duplicate root');
    requireThat(Array.isArray(mod.omitImports), 'Explicit omitImports array required');
    for (const omission of mod.omitImports) {
      requireThat(plain(omission), 'Invalid import omission'); keys(omission, ['alias', 'path'], 'omission');
      requireThat(text(omission.alias) && text(omission.path), 'Invalid import omission');
    }
    requireThat(mod.omitImports.every(item => plain(item) && item.alias === 'CheckerCore' && item.path === './checker_core_steps_v1.bend'), 'Only explicit CheckerCore omission is allowed; all other imports, including Template/Emit, must remain');
    const fixed = mod.candidate === 'emitter-arity50' ? ['emitter_continuation_1089', 'emitter_match_710'] :
      mod.candidate === 'parser-depth' ? ['encode_float_normal_rounding_limit', 'parse_unicode_digits'] :
      mod.candidate === 'parser-feedback' ? ['encode_float_normal_rounding_limit', 'parse_unicode_digits', 'feedback_resume_frame'] : null;
    if (fixed) {
      requireThat(mod.rootCriterion === undefined && JSON.stringify(mod.roots) === JSON.stringify(fixed), `Fixed roots changed for ${mod.candidate}`);
    } else if (mod.rootCriterion !== undefined) {
      requireThat(plain(mod.rootCriterion), 'Invalid arity criterion');
      keys(mod.rootCriterion, ['kind', 'minimum', 'expectedCount'], 'criterion');
      requireThat(mod.roots.length === 0 && mod.rootCriterion.kind === 'parameter-arity-at-least' && mod.rootCriterion.minimum === 20 && mod.rootCriterion.expectedCount === 30, 'Invalid preregistered arity criterion');
    } else requireThat(mod.roots.length === 30, 'Explicit wide-emitter list must contain all 30 roots');
  }
  for (const required of ['emitter-arity50', 'parser-depth', 'parser-feedback']) requireThat(candidates.has(required), `Missing separate candidate ${required}`);
}
function contained(root: string, file: string): boolean {
  const part = relative(root, file);
  return part !== '' && part !== '..' && !part.startsWith('..' + sep) && !isAbsolute(part);
}
function within(root: string, name: string): string {
  requireThat(!isAbsolute(name), `Universe path must be relative: ${name}`);
  const file = resolve(root, name);
  requireThat(contained(root, file), `Path escapes universe: ${name}`);
  return file;
}
function utf8(file: string): string {
  const bytes = readFileSync(file), source = bytes.toString('utf8');
  requireThat(Buffer.from(source, 'utf8').equals(bytes), `Non-roundtripping UTF-8: ${file}`);
  return source;
}
const sourceByteOffsets = new Map<string, Uint32Array>();
function byteOffsets(source: string): Uint32Array {
  const cached = sourceByteOffsets.get(source);
  if (cached) return cached;
  const offsets = new Uint32Array(source.length + 1);
  let bytes = 0;
  for (let index = 0; index < source.length; index++) {
    offsets[index] = bytes;
    const code = source.charCodeAt(index);
    if (code >= 0xd800 && code <= 0xdbff && source.charCodeAt(index + 1) >= 0xdc00 && source.charCodeAt(index + 1) <= 0xdfff) {
      offsets[++index] = bytes; bytes += 4;
    } else bytes += code < 0x80 ? 1 : code < 0x800 ? 2 : 3;
    requireThat(bytes <= 0xffffffff, 'Source byte offsets exceed census range');
  }
  offsets[source.length] = bytes;
  sourceByteOffsets.set(source, offsets);
  return offsets;
}
function range(source: string, begin: number, end: number): SpanRecord {
  requireThat(Number.isInteger(begin) && Number.isInteger(end) && begin >= 0 && end >= begin && end <= source.length, 'Invalid UTF-16 range');
  for (const at of [begin, end]) {
    const before = source.charCodeAt(at - 1), after = source.charCodeAt(at);
    requireThat(!(before >= 0xd800 && before <= 0xdbff && after >= 0xdc00 && after <= 0xdfff), 'Boundary splits surrogate pair');
  }
  const offsets = byteOffsets(source);
  return {beginUTF16: begin, endUTF16: end, beginByte: offsets[begin]!,
    endByte: offsets[end]!, sliceSHA256: sha(source.slice(begin, end))};
}
const tags: Record<string, true> = Object.fromEntries(['Var', 'Ref', 'Sub', 'Let', 'Typ', 'Qnt', 'Qua', 'Min', 'All', 'Lam', 'App', 'ADT', 'Ctr', 'Lit', 'Mat', 'Efq', 'Eql', 'Rfl', 'Rwt', 'Hol', 'Ann', 'PVar', 'PCtr', 'Match', 'Local', 'None', 'Lone', 'Many'].map(tag => [tag, true]));
/** Walk original indexed syntax, never call a function-valued term. Bound Var
 * alternatives remain conservative candidates: matching local/import names are
 * retained even when native binding resolution would discard the alternative. */
function references(declaration: RawDeclaration, laws: Set<string>, issues: Issue[], derived: ModuleReport['derivedSignatureCoverage']): Reference[] {
  const owner = declaration.key, roots: unknown[] = [declaration.body, declaration.vars, declaration.blocks,
    declaration.kindTerm, declaration.lawBody, declaration.lawType];
  // Parameter/law tuples also contain Span -> Parse -> Book provenance. Walking
  // those tuples would invoke unrelated lazy definition getters, not visit syntax.
  const parameters = (rows: RawDeclaration['parameters']) => {
    for (const row of rows ?? []) roots.push(row[0], row[3]);
  };
  parameters(declaration.parameters);
  for (const clause of declaration.clauses ?? []) roots.push(clause[1]);
  if (declaration.signature) {
    parameters(declaration.signature.parameters);
    roots.push(declaration.signature.result);
    if (declaration.signature.declaredType) {
      if (!declaration.completesLaw || !laws.has(owner)) issues.push({code: 'opaque-signature', owner, detail: 'No authentic local law supplies the completion signature'});
      else derived.push({key: owner, kind: 'law-completion', basis: 'Original local law clauses/type/body are selected and traversed; derived HOAS declaredType is not invoked'});
    }
  }
  for (const constructor of declaration.constructors ?? []) {
    parameters(constructor.fields);
    derived.push({key: constructor.key, kind: 'constructor', basis: 'Original datatype parameters, kind, all constructor fields and owning datatype are selected and traversed; derived HOAS constructor.type is not invoked'});
  }
  const refs: Reference[] = [];
  const visited = [new WeakSet<object>(), new WeakSet<object>()];
  function scan(value: unknown, optional = false): void {
    if (typeof value === 'function') { issues.push({code: 'unknown-callable', owner, detail: 'Callable encountered in authentic syntax; not invoked or ignored'}); return; }
    if (!value || typeof value !== 'object' || visited[Number(optional)]!.has(value)) return;
    visited[Number(optional)]!.add(value);
    if (Array.isArray(value)) { for (const child of value) scan(child, optional); return; }
    const node = value as Record<string, unknown>;
    if ('$' in node && !Object.hasOwn(tags, String(node.$))) issues.push({code: 'unsupported-syntax', owner, detail: String(node.$)});
    if (node.$ === 'Hol') issues.push({code: 'source-hole', owner, detail: String(node.k)});
    if (['Ref', 'ADT', 'Ctr', 'PCtr', 'Mat'].includes(String(node.$)) && typeof node.k === 'string') refs.push({key: node.k, owner, optional});
    if (node.$ === 'ADT' && Array.isArray(node.r)) for (const name of node.r) if (typeof name === 'string') refs.push({key: name, owner, optional});
    if (node.$ === 'Lit' && typeof node.k === 'string') refs.push({key: node.k, owner, optional});
    if (node.$ === 'Var' && typeof node.k === 'string') refs.push({key: node.k, owner, optional: true});
    for (const [key, child] of Object.entries(node)) if (key !== 's') {
      // Var.v is a fallback alternative, not an unconditional global Ref.
      // Keep every matching owner conservatively; nativeSourceClosure resolves
      // body binders. Standalone nested block IDs need not match outer IDs.
      scan(child, optional || (node.$ === 'Var' && key === 'v'));
    }
  }
  roots.forEach(root => scan(root));
  return refs;
}

export async function extractTails(planFile: string, reportFile: string): Promise<void> {
  const planPath = realpathSync(resolve(planFile)), reportPath = resolve(reportFile);
  requireThat(!existsSync(reportPath), 'Report must be fresh');
  const planBytes = readFileSync(planPath), value: unknown = JSON.parse(planBytes.toString('utf8'));
  validatePlan(value); const plan = value;
  const root = realpathSync(resolve(dirname(planPath), plan.sourceUniverse.directory));
  const observer = realpathSync(resolve(dirname(planPath), plan.observerStage0.file));
  requireThat(contained(root, observer), 'Observer must reside in frozen universe');
  requireThat(!contained(root, reportPath), 'Report must be outside frozen universe');
  const manifest = new Map<string, string>();
  for (const entry of plan.sourceUniverse.files) {
    const file = within(root, entry.path);
    requireThat(!manifest.has(file), `Duplicate manifest path: ${entry.path}`); manifest.set(file, entry.sha256);
  }
  if (manifest.has(observer)) requireThat(manifest.get(observer) === plan.observerStage0.sha256, 'Conflicting observer manifest hash');
  manifest.set(observer, plan.observerStage0.sha256);
  const destinations = new Set<string>(), destinationRoots = new Map<string, string>();
  const replaced = new Map<string, Set<string>>();
  for (const mod of plan.modules) {
    const source = within(root, mod.source);
    const targetRoot = realpathSync(resolve(dirname(planPath), mod.destinationDirectory));
    requireThat(targetRoot !== root && !contained(root, targetRoot) && !contained(targetRoot, root), 'Candidate tree must be separate from frozen input tree');
    requireThat(!contained(targetRoot, reportPath), 'Report must be outside candidate trees');
    for (const other of destinationRoots.values()) requireThat(other === targetRoot || (!contained(other, targetRoot) && !contained(targetRoot, other)), 'Candidate trees must not nest');
    destinationRoots.set(mod.id, targetRoot);
    const destination = within(targetRoot, mod.destination);
    requireThat(relative(root, source) === mod.source && relative(targetRoot, destination) === mod.source, 'Noncanonical or renamed original relative path');
    requireThat(manifest.has(source), `Unmanifested source: ${mod.source}`);
    requireThat(source.endsWith('.bend'), 'Source/destination must be Bend files');
    requireThat(realpathSync(dirname(destination)) === dirname(destination), 'Symlink destination directory');
    requireThat(!destinations.has(destination) && !existsSync(destination), `Destination must be fresh: ${mod.destination}`);
    destinations.add(destination);
    const names = replaced.get(targetRoot) ?? new Set<string>(); names.add(mod.source); replaced.set(targetRoot, names);
  }
  const reports: ModuleReport[] = [], created: string[] = [], staged = new Map<string, string>();
  const verification: {phase: string; files: number; observerSHA256: string; candidateDirectories: string[]}[] = [];
  let failure: string | undefined;
  function verify(phase: string): void {
    requireThat(sha(readFileSync(planPath)) === sha(planBytes), 'Plan changed during extraction');
    for (const [file, expected] of manifest) {
      requireThat(realpathSync(file) === file && lstatSync(file).isFile(), `Nonregular/symlink input: ${file}`);
      requireThat(sha(readFileSync(file)) === expected, `Input hash mismatch: ${file}`);
    }
    function inventory(directory: string, expected: Set<string>): void {
      for (const entry of readdirSync(directory, {withFileTypes: true})) {
        const file = resolve(directory, entry.name);
        requireThat(!entry.isSymbolicLink(), `Symlink in authenticated tree: ${file}`);
        if (entry.isDirectory()) inventory(file, expected);
        else requireThat(entry.isFile() && expected.has(file), `Unmanifested tree file: ${file}`);
      }
    }
    inventory(root, new Set(manifest.keys()));
    for (const [targetRoot, omittedSources] of replaced) {
      const expected = new Set<string>();
      for (const [input, hash] of manifest) {
        const name = relative(root, input), target = within(targetRoot, name);
        if (omittedSources.has(name)) {
          if (created.includes(target)) {
            expected.add(target);
            requireThat(sha(readFileSync(target)) === sha(staged.get(target)!), `Changed generated fragment: ${target}`);
          } else requireThat(!existsSync(target), `Replacement must remain fresh: ${target}`);
        } else {
          expected.add(target);
          requireThat(realpathSync(target) === target && lstatSync(target).isFile() && sha(readFileSync(target)) === hash, `Candidate supporting file differs: ${target}`);
        }
      }
      inventory(targetRoot, expected);
    }
    requireThat(sha(readFileSync(resolve(import.meta.dir, '../bend2/bend.ts'))) === plan.observerStage0.sha256, 'nativeSourceClosure stage0 differs from frozen observer');
    verification.push({phase, files: manifest.size, observerSHA256: sha(readFileSync(observer)), candidateDirectories: [...replaced.keys()]});
  }
  type Inventory = {
    declarations: {key: string; kind: string; constructors: {key: string}[]}[];
    imports: SourceOracleResult['imports']; loadContexts: SourceOracleResult['loadContexts'];
  };
  const cache = new Map<string, Promise<Inventory>>();
  const inventory = (oracle: SourceOracleResult): Inventory => ({
    declarations: oracle.declarations.map(item => ({key: item.key, kind: item.kind, constructors: (item.constructors ?? []).map(ctor => ({key: ctor.key}))})),
    imports: oracle.imports, loadContexts: oracle.loadContexts,
  });
  async function loadOracle(file: string): Promise<SourceOracleResult> {
    requireThat(manifest.has(file) && realpathSync(file) === file, `Unmanifested oracle root: ${file}`);
    const source = utf8(file);
    requireThat(sha(source) === manifest.get(file), `Oracle source changed: ${file}`);
    const oracle = await sourceOracle(file, source, {recordInputs: true, stage0File: observer});
    requireThat(oracle.accepted, `Source oracle rejected ${relative(root, file)}: ${JSON.stringify(oracle.failure)} ${String(oracle.error)}`);
    requireThat(oracle.observation.stage0Sha256 === plan.observerStage0.sha256, 'Observer hash mismatch');
    for (const input of oracle.inputFiles) requireThat(manifest.get(input.file) === input.sha256 && input.sha256 === input.sourceSha256 && input.requested === input.file, `Unmanifested/changed/aliased loader input: ${input.file}`);
    for (const context of oracle.loadContexts) requireThat(manifest.get(context.file) === context.sourceSha256, `Unauthenticated context: ${context.file}`);
    return oracle;
  }
  function observe(file: string): Promise<Inventory> {
    let pending = cache.get(file);
    if (!pending) { pending = loadOracle(file).then(inventory); cache.set(file, pending); }
    return pending;
  }
  try {
    verify('before');
    for (const mod of plan.modules) {
      const file = within(root, mod.source), oracle = await loadOracle(file), source = oracle.source;
      // Raw observations retain complete lazy books. Only compact ownership
      // metadata survives this module; no imported books or ASTs are cached.
      cache.set(file, Promise.resolve(inventory(oracle)));
      const declarations = oracle.declarations;
      requireThat(declarations.length > 0, `No authentic declarations: ${mod.source}`);
      const byName = new Map<string, RawDeclaration[]>(), constructors = new Map<string, string[]>();
      let previous = 0;
      for (const declaration of declarations) {
        requireThat(['def', 'type', 'law'].includes(declaration.kind) && declaration.beg >= previous && declaration.end > declaration.beg && declaration.end <= source.length, 'Unsupported/overlapping declaration boundaries');
        range(source, declaration.beg, declaration.end); previous = declaration.end;
        const entries = byName.get(declaration.key);
        if (entries) entries.push(declaration); else byName.set(declaration.key, [declaration]);
        for (const ctor of declaration.constructors ?? []) {
          const owners = constructors.get(ctor.key);
          if (owners) owners.push(declaration.key); else constructors.set(ctor.key, [declaration.key]);
        }
      }
      requireThat(declarations.at(-1)!.end === source.length || source.slice(declarations.at(-1)!.end).trim() === '', 'Unobserved trailing source syntax');
      const headerEnd = declarations[0]!.beg;
      requireThat(oracle.imports.every(item => item.end <= headerEnd), 'Imports outside original header');
      const wide = declarations.filter(item => item.kind === 'def' && (item.signature?.parameters?.length ?? -1) >= 20).map(item => item.key);
      const roots = mod.rootCriterion ? wide : mod.roots;
      if (mod.candidate === 'emitter-arity20') requireThat(wide.length === 30 && roots.length === 30 && wide.every(key => roots.includes(key)), 'Preregistered 30 wide-emitter roots do not match authentic parameter arities');
      if (mod.candidate === 'emitter-arity50') requireThat(byName.get('emitter_continuation_1087')?.some(item => item.signature?.parameters?.length === 50), 'Authentic 50-parameter continuation is missing');
      if (mod.candidate.startsWith('parser-')) requireThat(declarations.filter(item => item.kind === 'type').length === 36 && byName.has('FeedbackFrame'), 'Parser inventory lacks 36 authentic types/FeedbackFrame');
      const report: ModuleReport = {id: mod.id, candidate: mod.candidate, source: mod.source, destination: mod.destination,
        sourceDirectory: root, destinationDirectory: destinationRoots.get(mod.id)!, originalRelativePathPreserved: true,
        originalSHA256: manifest.get(file)!, status: 'inconclusive', roots: [...roots], rootCriterion: mod.rootCriterion, issues: [],
        selectedDefinitions: [], droppedFunctions: [], originalImports: [], omittedImports: [], externalReferences: [], unresolvedExternalRefs: [], derivedSignatureCoverage: [], header: range(source, 0, headerEnd)};
      reports.push(report);
      const selected = new Set<string>(), reasons = new Map<string, Set<string>>(), queue: string[] = [];
      function include(key: string, reason: string): void {
        if (!byName.has(key)) { report.issues.push({code: 'missing-local-definition', detail: key}); return; }
        const why = reasons.get(key) ?? new Set<string>(); why.add(reason); reasons.set(key, why);
        if (!selected.has(key)) { selected.add(key); queue.push(key); }
      }
      for (const key of roots) {
        requireThat(byName.get(key)?.some(item => item.kind === 'def' && item.body), `Missing authentic root body: ${key}`);
        include(key, 'preregistered-root');
      }
      const laws = new Set(declarations.filter(item => item.kind === 'law').map(item => item.key));
      for (const declaration of declarations) if (declaration.kind !== 'def') include(declaration.key, 'all-local-types-and-laws');
      // Preflight raw syntax before the existing resolver can visit any body.
      // An unsupported callable anywhere is an explicit conservative refusal.
      const scanned = new Map(declarations.map(declaration => [declaration, references(declaration, laws, report.issues, report.derivedSignatureCoverage)]));
      const allRefs: Reference[] = [], nativeCovered = new Set<string>();
      for (let cursor = 0; cursor < queue.length; cursor++) {
        const key = queue[cursor]!;
        if (report.issues.length === 0 && !nativeCovered.has(key) && byName.get(key)!.some(item => item.body)) {
          try {
            for (const dependency of nativeSourceClosure(oracle, key)) {
              include(dependency, `native-body:${key}`); nativeCovered.add(dependency);
            }
          } catch (error) { report.issues.push({code: 'native-closure-failed', owner: key, detail: String(error)}); }
        }
        for (const declaration of byName.get(key)!) {
          if (declaration.nativeImports?.length) report.issues.push({code: 'native-definition', owner: key, detail: 'Native payload dependencies are unsupported for a selected fragment definition'});
          if (declaration.kind === 'def' && !declaration.body && !declaration.nativeImports) report.issues.push({code: 'missing-body', owner: key, detail: 'No authentic function body observed'});
          const refs = scanned.get(declaration)!; allRefs.push(...refs);
          for (const ref of refs) {
            if (byName.has(ref.key)) include(ref.key, `syntax:${key}`);
            for (const owner of constructors.get(ref.key) ?? []) include(owner, `constructor:${key}:${ref.key}`);
          }
        }
      }
      if (mod.candidate === 'emitter-arity50' && !selected.has('emitter_continuation_1087')) report.issues.push({code: 'missing-width-tail', detail: 'Preregistered roots did not close over the authentic 50-parameter continuation'});
      const imports: {alias: string; path: string; file: string; omitted: boolean; reachable: Set<string>}[] = [];
      const omissionKeys = mod.omitImports.map(item => JSON.stringify([item.alias, item.path]));
      requireThat(new Set(omissionKeys).size === omissionKeys.length, 'Duplicate import omission');
      for (const item of oracle.imports) {
        requireThat(item.resolved !== undefined && manifest.has(item.resolved), `Unresolved original import ${item.alias}:${item.path}`);
        const imported = await observe(item.resolved);
        imports.push({alias: item.alias, path: item.path, file: item.resolved, omitted: omissionKeys.includes(JSON.stringify([item.alias, item.path])), reachable: new Set(imported.loadContexts.map(context => context.file))});
        report.originalImports.push({alias: item.alias, path: item.path, namespace: item.namespace, resolved: relative(root, item.resolved), original: range(source, item.beg, item.end)});
      }
      for (const omission of mod.omitImports) requireThat(imports.filter(item => item.alias === omission.alias && item.path === omission.path).length === 1, `Omission does not identify exactly one original import: ${omission.alias}`);
      const pendingRefs = new Map<string, Reference[]>();
      for (const ref of allRefs) if (!byName.has(ref.key) && !constructors.has(ref.key)) {
        const group = pendingRefs.get(ref.key);
        if (group) group.push(ref); else pendingRefs.set(ref.key, [ref]);
      }
      const usedFiles = new Set<string>();
      for (const [key, refs] of pendingRefs) {
        const owners = new Set<string>(), definitions: {source: string; key: string}[] = [];
        for (const context of oracle.loadContexts) {
          if (context.file === file) continue;
          const prefix = context.namespace ? context.namespace + ':' : '';
          if (!key.startsWith(prefix)) continue;
          const local = key.slice(prefix.length), imported = await observe(context.file);
          if (imported.declarations.some(item => item.key === local || item.constructors?.some(ctor => ctor.key === local))) {
            owners.add(context.file);
            const source = relative(root, context.file);
            if (!definitions.some(item => item.source === source && item.key === local)) definitions.push({source, key: local});
          }
        }
        const referencedBy = [...new Set(refs.map(ref => ref.owner))].sort();
        if (owners.size === 0) {
          if (refs.some(ref => !ref.optional)) report.unresolvedExternalRefs.push({key, referencedBy});
          continue;
        }
        for (const owner of owners) usedFiles.add(owner);
        const retainedVia = imports.filter(item => !item.omitted && [...owners].some(owner => item.reachable.has(owner))).map(item => item.alias);
        report.externalReferences.push({key, owners: [...owners].map(owner => relative(root, owner)).sort(), definitions, referencedBy, retainedVia});
        for (const owner of owners) if (!imports.some(item => !item.omitted && item.reachable.has(owner))) report.issues.push({code: 'external-closure-requirement', detail: `${key} requires ${relative(root, owner)} through an omitted import`});
      }
      if (report.unresolvedExternalRefs.length) report.issues.push({code: 'unresolved-external-references', detail: 'Authentic reference has no observed local/constructor/imported declaration owner'});
      for (const item of imports.filter(item => item.omitted)) {
        if (usedFiles.has(item.file)) report.issues.push({code: 'import-closure-requirement', detail: `Selected authentic syntax references ${item.alias}; retain ${item.path}`});
        else report.omittedImports.push({alias: item.alias, path: item.path, proof: 'no-selected-reference-to-module-and-all-external-owners-retained'});
      }
      let output = source.slice(0, headerEnd);
      for (const item of [...oracle.imports].sort((a, b) => b.beg - a.beg)) if (imports.some(entry => entry.alias === item.alias && entry.path === item.path && entry.omitted)) output = output.slice(0, item.beg) + output.slice(item.end);
      let emittedBytes = Buffer.byteLength(output);
      for (let index = 0; index < declarations.length; index++) {
        const declaration = declarations[index]!, prefixBegin = index === 0 ? declaration.beg : declarations[index - 1]!.end;
        if (!selected.has(declaration.key)) {
          if (declaration.kind === 'def') report.droppedFunctions.push({key: declaration.key, original: range(source, declaration.beg, declaration.end)});
          continue;
        }
        const slice = source.slice(prefixBegin, declaration.end), emittedBegin = output.length;
        output += slice;
        const sliceBytes = byteOffsets(source)[declaration.end]! - byteOffsets(source)[prefixBegin]!;
        report.selectedDefinitions.push({key: declaration.key, kind: declaration.kind, arity: declaration.signature?.parameters?.length ?? null,
          reason: [...reasons.get(declaration.key)!].sort(), original: range(source, declaration.beg, declaration.end), prefix: range(source, prefixBegin, declaration.beg),
          emitted: {beginUTF16: emittedBegin, endUTF16: output.length, beginByte: emittedBytes, endByte: emittedBytes + sliceBytes, sliceSHA256: sha(slice)}});
        emittedBytes += sliceBytes;
      }
      const suffix = source.slice(declarations.at(-1)!.end); output += suffix;
      if (report.issues.length === 0) {
        report.status = 'complete'; report.outputSHA256 = sha(output); report.outputBytes = Buffer.byteLength(output);
        staged.set(within(destinationRoots.get(mod.id)!, mod.destination), output);
      } else report.omittedImports = []; // No omission proof or artifact is certified on an inconclusive module.
    }
    // A retained import may load another generated fragment in this candidate
    // tree. Original-universe symbol ownership alone does not prove that the
    // replacement still exports it.
    for (const report of reports) for (const ref of report.externalReferences) for (const definition of ref.definitions) {
      const provider = reports.find(item => item.destinationDirectory === report.destinationDirectory && item.source === definition.source);
      if (!provider) continue;
      const original = await observe(within(root, provider.source));
      const owners = original.declarations.filter(item => item.key === definition.key || item.constructors?.some(ctor => ctor.key === definition.key));
      if (!owners.some(owner => provider.selectedDefinitions.some(item => item.key === owner.key))) {
        report.status = 'inconclusive'; report.omittedImports = [];
        report.issues.push({code: 'replacement-closure-requirement', detail: `${ref.key} requires ${definition.key} in candidate fragment ${provider.id}`});
      }
    }
    // Whole retained dependencies have not been pruned. If one imports a
    // replacement, preserving all of that replacement's exports is sufficient;
    // otherwise refuse rather than infer that the whole dependency ignores it.
    for (const report of reports) {
      const retained = report.originalImports.filter(item => !report.omittedImports.some(omitted => omitted.alias === item.alias && omitted.path === item.path));
      for (const imported of retained) {
        const dependency = await observe(within(root, imported.resolved));
        for (const context of dependency.loadContexts) {
          const source = relative(root, context.file);
          if (reports.some(item => item.destinationDirectory === report.destinationDirectory && item.source === source)) continue;
          const whole = await observe(context.file);
          for (const provider of reports.filter(item => item.destinationDirectory === report.destinationDirectory)) {
            if (!whole.imports.some(item => item.resolved === within(root, provider.source))) continue;
            const providerOriginal = await observe(within(root, provider.source));
            if (providerOriginal.declarations.every(item => provider.selectedDefinitions.some(selected => selected.key === item.key && selected.kind === item.kind))) continue;
            report.status = 'inconclusive'; report.omittedImports = [];
            report.issues.push({code: 'whole-import-replacement-requirement', detail: `Retained whole ${source} imports pruned ${provider.source}; its full export requirement is not certified`});
          }
        }
      }
      if (report.status !== 'complete') { delete report.outputSHA256; delete report.outputBytes; }
    }
    verify('after-observation');
    if (reports.every(report => report.status === 'complete')) {
      for (const [file, source] of staged) { writeFileSync(file, source, {flag: 'wx'}); created.push(file); }
      for (const [file, source] of staged) requireThat(readFileSync(file).equals(Buffer.from(source)), `Output byte mismatch: ${file}`);
    }
  } catch (error) { failure = String(error); }
  try { verify('after'); } catch (error) { failure = [failure, String(error)].filter(Boolean).join('\n'); }
  if (failure || reports.some(report => report.status !== 'complete')) {
    for (const file of created) unlinkSync(file);
    created.length = 0;
  }
  const report = {schemaVersion: 1, status: failure ? 'failed' : reports.every(item => item.status === 'complete') ? 'complete' : 'inconclusive',
    planFile: planPath, planSHA256: sha(planBytes), extractorSHA256: sha(readFileSync(import.meta.path)),
    sourceUniverse: {directory: root, files: plan.sourceUniverse.files}, observerStage0: {file: observer, sha256: plan.observerStage0.sha256},
    verification, failure, modules: reports, writtenDestinations: created,
    structuralInterpretation: {
      parserPatternDepths: [
        {root: 'encode_float_normal_rounding_limit', depth: 131, pattern: '127n'},
        {root: 'parse_unicode_digits', depth: 128, pattern: '125n'},
      ],
      provenance: 'Preregistered parent source observations, not measured by this extractor',
      meaning: 'Recursively lowered Nat-pattern depth; neither authored expression nesting nor native semantic depth',
      fullDispatcher: 'feedback_resume_frame retention/omission is explicit in selectedDefinitions/droppedFunctions; only parser-feedback roots require it',
    },
    limitations: ['Source dependency closure only; no native parse/check/emit acceptance or performance claim.',
      'All local types and laws are retained, including the complete authentic FeedbackFrame; closure can therefore approach the whole source.',
      'Original relative filenames, aliases and namespaces are preserved in separate candidate trees. Imports retain whole modules unless explicitly replaced by another audited fragment in that tree.',
      'Conservative bound-variable alternatives and ambiguous owners may retain extra functions/imports.',
      'Known derived constructor/completion HOAS signatures use their authentic raw declaration counterparts; other callable syntax is inconclusive.',
      'sourceOracle may perform its existing nested-block parser lowering; this extractor never requests normalizationBook or evaluates a target definition.',
      'nativeSourceClosure imports the repository stage0; its bytes must equal the frozen observer. Source helper and resolver hashes are recorded.',
      'Exclusive output creation is per-file, not a multi-file filesystem transaction; failures roll back only this invocation\'s created destinations.'],
    implementationInputs: ['bootstrap_source_oracle.ts', 'native_match_source.ts', '../bend2/bend.ts'].map(file => ({file, sha256: sha(readFileSync(resolve(import.meta.dir, file)))}))};
  try { writeFileSync(reportPath, JSON.stringify(report, null, 2) + '\n', {flag: 'wx'}); }
  catch (error) {
    for (const file of created) unlinkSync(file);
    throw error;
  }
  if (report.status !== 'complete') throw Error(`Tail extraction ${report.status}; see ${reportPath}`);
}
if (import.meta.main) {
  const args = process.argv.slice(2);
  if (args.length !== 2) { console.error('Usage: bun evals/selfhost_corpus_tails.ts PLAN.json FRESH-REPORT.json'); process.exitCode = 1; }
  else try { await extractTails(args[0]!, args[1]!); } catch (error) { console.error(String(error)); process.exitCode = 1; }
}
