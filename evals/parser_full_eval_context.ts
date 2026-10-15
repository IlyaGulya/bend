/** AST/binder-ID evaluation-context factoring for the unchanged feedback lowerer.
 * Only immediate single-effect contexts are extracted. Helpers retain the whole
 * lexical continuation (including Local bindings and remainder), rather than
 * evaluating pure siblings early or deriving captures from source spellings.
 * Closed transport types are required by the existing Request/Kont ABI.
 */
import { posix } from 'node:path';
import { term_show, term_unapply, type Body, type LTerm, type Span } from '../bend2/bend.ts';
import { readParserGraph, type ParserGraph, type ParserParameter, type ParserSignature } from './parser_full_graph.ts';
import { LexicalTypes, freeBinderIds, termChildren, type Binding } from './parser_full_type_env.ts';
import { lexicalBodyCaptures } from './parser_full_lexical_body_capture.ts';
import { renderBody } from './parser_full_body_render.ts';
import { SourceDeclarations } from './parser_full_declarations.ts';

export type ContextRow = {
  owner: string;
  producer: string;
  offset: number;
  depth: number;
  captures: Binding[];
  helper: string;
};
export type EvaluationContextEvidence = {
  owner?: string;
  offset?: number;
  producers?: readonly string[];
  [key: string]: unknown;
};
export class EvaluationContextLimitation extends Error {
  constructor(readonly code: string, message: string, readonly evidence: EvaluationContextEvidence) {
    super(message);
    this.name = 'EvaluationContextLimitation';
  }
  toJSON() { return { code: this.code, message: this.message, evidence: this.evidence }; }
}

type Effect = { term: LTerm; name: string; offset: number; depth: number };
type Effects = { immediate: Effect[]; delayed: Effect[] };

/** Traverse maximal application spines, never count their partial prefixes. */
function expressionEffects(expression: LTerm, effectful: ReadonlySet<string>): Effects {
  const immediate: Effect[] = [], delayed: Effect[] = [];
  function visit(term: LTerm, depth: number, underLambda: boolean): Effect[] {
    if (term.$ === 'Lam') { visit(term.f, depth + 1, true); return []; }
    if (term.$ === 'App') {
      const [head, args] = term_unapply(term);
      const descendants = args.flatMap(arg => visit(arg, depth + 1, underLambda));
      if (head.$ !== 'Ref') descendants.push(...visit(head, depth + 1, underLambda));
      if (head.$ === 'Ref' && effectful.has(head.k) && !descendants.length) {
        const effect = { term, name: head.k, offset: head.s?.beg ?? term.s?.beg ?? -1, depth };
        (underLambda ? delayed : immediate).push(effect);
        return [effect];
      }
      return descendants;
    }
    return termChildren(term).flatMap(child => visit(child, depth + 1, underLambda));
  }
  visit(expression, 0, false);
  return { immediate, delayed };
}

/** Structural reconstruction shares untouched children, never mutates input ASTs. */
function mapTerm(term: LTerm, replace: (term: LTerm) => LTerm | undefined): LTerm {
  const replacement = replace(term);
  if (replacement) return replacement;
  const children = termChildren(term);
  if (!children.length) return term;
  const mapped = new Map(children.map(child => [child, mapTerm(child, replace)]));
  const result = { ...term } as unknown as Record<string, unknown>;
  for (const [key, value] of Object.entries(term)) {
    if (key === 's') continue;
    if (Array.isArray(value)) result[key] = value.map(child => mapped.get(child) ?? child);
    else if (value && typeof value === 'object') result[key] = mapped.get(value as LTerm) ?? value;
  }
  return result as LTerm;
}
function bodyExpressions(body: Body, visit: (term: LTerm) => void): void {
  if (body.$ === 'Local') { body.v.forEach(visit); bodyExpressions(body.f, visit); }
  else if (body.$ === 'Match') { body.e.forEach(visit); body.r.forEach(row => bodyExpressions(row.f, visit)); }
  else visit(body);
}
function entry(body: Body): LTerm {
  const expression = body.$ === 'Local' ? body.v[0] : body.$ === 'Match' ? body.e[0] : body;
  if (!expression) throw Error('Evaluation context has no entry expression');
  return expression;
}
function effectReachability(bodies: ReadonlyMap<string, Body>, seeds: readonly string[]): Set<string> {
  const reverse = new Map<string, Set<string>>();
  for (const [owner, body] of bodies) bodyExpressions(body, expression => {
    function visit(term: LTerm): void {
      if (term.$ === 'Ref' && bodies.has(term.k)) {
        const callers = reverse.get(term.k) ?? new Set<string>();
        callers.add(owner); reverse.set(term.k, callers);
      }
      termChildren(term).forEach(visit);
    }
    visit(expression);
  });
  const effectful = new Set(seeds.filter(seed => bodies.has(seed)));
  const queue = [...effectful];
  for (let index = 0; index < queue.length; index++) for (const caller of reverse.get(queue[index]!) ?? []) {
    if (!effectful.has(caller)) { effectful.add(caller); queue.push(caller); }
  }
  return effectful;
}

export async function normalizeEvaluationContexts(source: string, seeds: readonly string[]): Promise<{
  source: string; graph: ParserGraph; contexts: ContextRow[]; sourceSpecificTransformerExceptions: 0;
}> {
  const original = await readParserGraph(source);
  if (original.unresolvedReferences.length) throw new EvaluationContextLimitation('UnresolvedReferences',
    'Evaluation-context source has unresolved references', { references: original.unresolvedReferences });
  const bodies = new Map(original.bodies), signatures = new Map(original.signatures);
  const contexts: ContextRow[] = [], changed = new Set<string>();
  const origins = new Map(original.definitions.map(name => [name, name]));
  let fresh = 0;
  const seen = new WeakSet<object>();
  function reserve(value: unknown): void {
    if (!value || typeof value !== 'object' || seen.has(value)) return;
    seen.add(value);
    for (const [key, child] of Object.entries(value)) {
      if (key === 's') continue;
      if (key === 'i') for (const id of Array.isArray(child) ? child : [child]) {
        if (typeof id === 'number') fresh = Math.max(fresh, id + 1);
      }
      else reserve(child);
    }
  }
  for (const body of bodies.values()) reserve(body);
  for (const signature of signatures.values()) reserve(signature);

  // Keep source coordinates and binder identities through the fixed point;
  // reparsing each intermediate helper would destroy their lexical provenance.
  for (;;) {
    const effectful = effectReachability(bodies, seeds);
    let factored = false;
    for (const [name, body] of bodies) {
      const signature = signatures.get(name)!;
      const owner = origins.get(name)!;
      let lexical: LexicalTypes | undefined;
      function stop(code: string, message: string, effects: readonly Effect[], extra: Record<string, unknown> = {}): never {
        throw new EvaluationContextLimitation(code, message, {
          owner, offset: effects[0]?.offset ?? -1,
          producers: effects.map(effect => effect.name),
          calls: effects.map(effect => ({ name: effect.name, offset: effect.offset, depth: effect.depth })), ...extra,
        });
      }
      function types(effect: Effect): LexicalTypes {
        if (!lexical) {
          lexical = new LexicalTypes(original.parserBook, signatures);
          try { lexical.indexBody(body, signature.parameters, signature.result); }
          catch (error) { stop('UnsupportedTyping', 'Cannot type the lexical evaluation context', [effect], { reason: error instanceof Error ? error.message : String(error) }); }
        }
        return lexical;
      }
      function extract(continuation: Body, effect: Effect): Body {
        const lexical = types(effect), producerSignature = signatures.get(effect.name)!;
        let resultType: LTerm;
        try { resultType = lexical.typeOf(effect.term); }
        catch (error) { stop('UnsupportedTyping', 'Cannot infer the suspended producer result', [effect], { reason: error instanceof Error ? error.message : String(error) }); }
        if (freeBinderIds(producerSignature.result).length || freeBinderIds(resultType).length || freeBinderIds(signature.result).length) {
          stop('DependentTransport', 'Dependent producer or owner results cannot be transported by the existing continuation ABI', [effect]);
        }
        const resultId = fresh++, result: LTerm = { $: 'Var', k: 'evaluation_result', i: resultId };
        const rewritten: Body = continuation.$ === 'Local'
          ? { ...continuation, v: continuation.v.map(value => mapTerm(value, term => term === effect.term ? result : undefined)) }
          : continuation.$ === 'Match'
            ? stop('UnsupportedContext', 'Only terminal and Local initializer contexts can be extracted', [effect])
            : mapTerm(continuation, term => term === effect.term ? result : undefined);
        // New expression roots have no WeakMap entry. Captures still enter at
        // the exact original expression scope, with only the result supplied.
        const captureTypes = Object.create(lexical) as LexicalTypes;
        const rewrittenEntry = entry(rewritten), originalEntry = entry(continuation);
        captureTypes.environmentAt = expression => lexical.environmentAt(expression === rewrittenEntry ? originalEntry : expression);
        let captures: Binding[];
        try { captures = lexicalBodyCaptures(rewritten, captureTypes, { providedIds: new Set([resultId]) }); }
        catch (error) { stop('UnsupportedTyping', 'Cannot close the lexical continuation captures', [effect], { reason: error instanceof Error ? error.message : String(error) }); }
        for (const capture of captures) if (freeBinderIds(capture.type).length) {
          stop('DependentTransport', 'Dependent capture types cannot be transported by the existing continuation ABI', [effect], { binderId: capture.id, capture: capture.name });
        }
        const helper = `evaluation_context_${owner}_${effect.offset}`;
        if (bodies.has(helper)) stop('HelperNameCollision', 'Deterministic evaluation-context helper name is already defined', [effect], { helper });
        const span: Span = effect.term.s ?? {file:{str:source,ns:'',al:{}},beg:effect.offset,end:effect.offset};
        const parameters: ParserParameter[] = captures.map(capture => [capture.quantity, capture.name, capture.id, capture.type, span]);
        parameters.push([{ $: 'Lone' }, 'evaluation_result', resultId, resultType, span]);
        const helperSignature: ParserSignature = { parameters, result: signature.result };
        bodies.set(helper, rewritten); signatures.set(helper, helperSignature); origins.set(helper, owner);
        contexts.push({ owner, producer: effect.name, offset: effect.offset, depth: effect.depth, captures, helper });
        let invocation: LTerm = { $: 'Ref', k: helper, s: span };
        for (const argument of [...captures.map(capture => ({ $: 'Var' as const, k: capture.name, i: capture.id })), effect.term]) {
          invocation = { $: 'App', f: invocation, x: argument, s: span };
        }
        factored = true;
        return { ...invocation, s: continuation.s };
      }
      function inspect(expressions: readonly LTerm[], terminal: boolean): Effect | undefined {
        const found = expressions.map(expression => expressionEffects(expression, effectful));
        const immediate = found.flatMap(effects => effects.immediate), delayed = found.flatMap(effects => effects.delayed);
        if (immediate.length > 1) stop('MultipleSuspendedEffects', 'multiple-effect evaluation context requires sequencing', immediate);
        const expression = expressions[0];
        const [head, args] = expression?.$ === 'App' ? term_unapply(expression) : [expression, [] as LTerm[]];
        const namedTerminal = terminal && head?.$ === 'Ref' && signatures.has(head.k);
        // Callback-consumer lambda lowering is an existing generator feature.
        // Delayed bodies are not immediate producer candidates.
        if (!immediate.length) {
          if (delayed.length && !namedTerminal) stop('DelayedLambdaEffect', 'An effect under a delayed lambda is not an immediate evaluation context', delayed);
          return;
        }
        const effect = immediate[0]!;
        if (terminal && (expression === effect.term || (namedTerminal && args.some(argument => argument === effect.term)))) return;
        if (delayed.length) stop('DelayedLambdaEffect', 'Factoring this context would transport an unsupported delayed effect', delayed);
        return effect;
      }
      function visit(node: Body): Body {
        if (factored) return node;
        if (node.$ !== 'Local' && node.$ !== 'Match') {
          const effect = inspect([node], true);
          return effect ? extract(node, effect) : node;
        }
        if (node.$ === 'Local') {
          const effect = inspect(node.v, false);
          if (effect) return extract(node, effect);
          const remainder = visit(node.f);
          return remainder === node.f ? node : { ...node, f: remainder };
        }
        const scrutineeEffects = node.e.flatMap(expression => expressionEffects(expression, effectful).immediate);
        if (scrutineeEffects.length) stop('UnsupportedContext', 'Effectful Match scrutinees require a separate match-continuation rule', scrutineeEffects);
        return { ...node, r: node.r.map(row => ({ ...row, f: visit(row.f) })) };
      }
      const rewritten = visit(body);
      if (factored) { bodies.set(name, rewritten); changed.add(name); break; }
    }
    if (!factored) break;
  }

  const aliases = [...source.matchAll(/^import (\S+) as ([A-Za-z_]\w*)$/gm)].map(match => {
    const path = posix.normalize(match[1]!).replace(/\.bend$/, '');
    return { path, namespace: posix.basename(path), alias: match[2]! };
  });
  const surfaceFile = {str: source, ns: '', al: Object.fromEntries(
    aliases.map(alias => [alias.alias, alias.namespace]))};
  function surfaceExpression(term: LTerm, names: string[], precedence: number): string {
    return term_show(term, precedence, names, surfaceFile);
  }
  function definition(name: string): string {
    const signature = signatures.get(name)!;
    const rendered = renderBody(bodies.get(name)!, signature.parameters, { book: original.parserBook, showTerm: surfaceExpression });
    return `def ${name}(${rendered.parameters}) -> ${rendered.renderTerm(signature.result)}:\n${rendered.body}\n\n`;
  }
  const declarations = new SourceDeclarations(source);
  const helpers = [...bodies.keys()].filter(name => !original.bodies.has(name));
  const replacements = [...changed].filter(name => original.bodies.has(name)).map(name => {
    const declaration = declarations.declarations.get(name)!;
    // Later extractions are dependencies of earlier continuation helpers.
    const prerequisites = helpers.filter(helper => origins.get(helper) === name).reverse();
    return { begin: declaration.start - declaration.prefix.length, end: declaration.end,
      text: prerequisites.map(definition).join('') + declarations.emit(name, definition(name)) };
  }).sort((a, b) => b.begin - a.begin);
  let normalized = source;
  for (const { begin, end, text } of replacements) normalized = normalized.slice(0, begin) + text + normalized.slice(end);
  const graph = helpers.length ? await readParserGraph(normalized) : original;
  if (graph.unresolvedReferences.length) throw new EvaluationContextLimitation('UnresolvedReferences',
    'Factored source has unresolved references', { references: graph.unresolvedReferences });
  return { source: normalized, graph, contexts, sourceSpecificTransformerExceptions: 0 };
}
