/** Fixture-only body extraction using the production cursor planner/renderer.
 * Extract exclusive Matches together when all cursors are already bound.
 * Otherwise descend to preserve nested cursor binding and ownership boundaries.
 */
import * as B from '../bend2/bend.ts';
import { fixtureRow } from './parser_full_body_capture_source.ts';
import { renderBody, type BodyRenderContext } from './parser_full_body_render.ts';
import { readParserGraph, type ParserGraph, type ParserParameter } from './parser_full_graph.ts';
import { lexicalBodyCaptures } from './parser_full_lexical_body_capture.ts';
import { LexicalTypes, termChildren } from './parser_full_type_env.ts';
import { planPatternScanCursorCall, renderPatternScanCursorCall } from './pattern_scan_partition_source.ts';

export type ScannerCursorCallEvidence = {
  originalOffset: number;
  firstArgument: B.LTerm;
  cursorFormal: string;
  remainingArguments: readonly B.LTerm[];
  substitutedArguments: B.LTerm[];
  astEquivalent: true;
  directCall: string;
  sourceQuantity: B.Quant;
  cursorHelper: string;
  cursorParameterIndex: number;
  helperCallIndex: number;
};
export type ScannerCursorOwnership = {
  cursorHelper: string; callbackHelper: string;
  cursorQuantities: B.Quant[]; callbackQuantities: B.Quant[];
  cursorCaptureIds: number[];
};
export type ScannerCursorFixtureFactoring = {
  original: ParserGraph;
  cursorSource: string;
  callbackSource: string;
  cursorGraph: ParserGraph;
  callbackGraph: ParserGraph;
  evidence: ScannerCursorCallEvidence[];
  ownership: ScannerCursorOwnership[];
};

/** Count syntax references, not reduced calls or source-text occurrences. */
export function scannerReferencesUnderLambda(body: B.Body): number {
  let count = 0;
  function term(node: B.LTerm, underLambda = false) {
    if (node.$ === 'Ref' && node.k === 'pattern_scan' && underLambda) count++;
    for (const child of termChildren(node)) term(child, underLambda || node.$ === 'Lam');
  }
  function visit(node: B.Body) {
    if (node.$ === 'Local') { node.v.forEach(value => term(value)); visit(node.f); }
    else if (node.$ === 'Match') { node.e.forEach(value => term(value)); node.r.forEach(row => visit(row.f)); }
    else term(node);
  }
  visit(body);
  return count;
}

function replaceTerm(node: B.LTerm, replacement: (node: B.LTerm) => B.LTerm | undefined): B.LTerm {
  const replaced = replacement(node);
  if (replaced) return replaced;
  const children = termChildren(node);
  const result = { ...node } as unknown as Record<string, unknown>;
  for (const [key, value] of Object.entries(node)) {
    if (key === 's') continue;
    if (Array.isArray(value)) result[key] = value.map(child => children.includes(child) ? replaceTerm(child, replacement) : child);
    else if (children.includes(value as B.LTerm)) result[key] = replaceTerm(value as B.LTerm, replacement);
  }
  return result as B.LTerm;
}

/** Keep both a tail's original pattern and refinements of that same tail. */
function tokenLineage(body: B.Body, tokenId: number): Map<number, B.Patt> {
  const roots = new Map<number, B.Patt>();
  function graft(pattern: B.Patt, id: number, replacement: B.Patt): B.Patt {
    if (pattern.$ === 'PVar') return pattern.i === id ? replacement : pattern;
    return { ...pattern, x: pattern.x.map(child => graft(child, id, replacement)) };
  }
  function tails(pattern: B.Patt, root: B.Patt) {
    if (pattern.$ === 'PVar') { if (pattern.k !== '_') roots.set(pattern.i, root); return; }
    if (pattern.k === 'Con') tails(pattern.x[1]!, root);
  }
  function visit(node: B.Body) {
    if (node.$ !== 'Local' && node.$ !== 'Match') return;
    if (node.$ === 'Local') { visit(node.f); return; }
    for (const row of node.r) {
      node.e.forEach((expression, index) => {
        if (expression.$ !== 'Var') return;
        const pattern = row.p[index]!;
        const parent = roots.get(expression.i);
        if (expression.i === tokenId) tails(pattern, pattern);
        else if (parent) tails(pattern, graft(parent, expression.i, pattern));
      });
      visit(row.f);
    }
  }
  visit(body);
  return roots;
}

export async function factorScannerCursorFixture(source: string, path: readonly number[]): Promise<ScannerCursorFixtureFactoring> {
  const original = await readParserGraph(source);
  const signature = original.signatures.get('example')!;
  const scanner = original.signatures.get('pattern_scan')!;
  const body = original.bodies.get('example')!;
  const lexical = new LexicalTypes(original.parserBook, original.signatures);
  lexical.indexBody(body, signature.parameters, signature.result);
  const lineage = tokenLineage(body, signature.parameters[0]![2]);
  const fileId = signature.parameters[1]![2];
  const selected = fixtureRow(original, path);
  function bodySpan(node: B.Body): B.Span {
    if (node.$ !== 'Local' && node.$ !== 'Match') {
      if (!node.s) throw Error('Fixture terminal lacks a source span');
      return node.s;
    }
    const first = node.$ === 'Match' ? node.e[0] : node.v[0];
    if (!first?.s) throw Error('Fixture body lacks an entry source span');
    const start = source.lastIndexOf('\n', first.s.beg) + 1;
    const beg = start + source.slice(start).match(/^[ \t]*/)![0].length;
    const end = node.$ === 'Local' ? bodySpan(node.f).end : Math.max(...node.r.map(row => bodySpan(row.f).end));
    return { file: first.s.file, beg, end };
  }
  const extractions: B.Body[] = [];
  function visit(node: B.Body) {
    const span = bodySpan(node);
    const calls = original.calls.get('example')!.filter(call => call.callee === 'pattern_scan' && call.offset >= span.beg && call.offset < span.end);
    if (!calls.length) return;
    const captures = new Set(lexicalBodyCaptures(node, lexical).map(binding => binding.id));
    if (calls.every(call => call.args[0]?.$ === 'Var' && captures.has(call.args[0].i))) {
      extractions.push(node);
    } else if (node.$ === 'Local') visit(node.f);
    else if (node.$ === 'Match') node.r.forEach(row => visit(row.f));
    else throw Error('Fixture cursor is not bound at terminal entry');
  }
  visit(selected.f);
  const callbackType = scanner.parameters.slice(2).reduceRight<B.LTerm>((result, parameter) => ({
    $: 'All', q: parameter[0], k: parameter[1], i: parameter[2], A: parameter[3], B: result,
  }), scanner.result);
  const cursorHelpers: string[] = [], callbackHelpers: string[] = [];
  const cursorPatches: { beg: number; end: number; source: string }[] = [];
  const callbackPatches: typeof cursorPatches = [];
  const evidence: ScannerCursorCallEvidence[] = [];
  const ownership: ScannerCursorOwnership[] = [];

  for (const reply of extractions) {
    const span = bodySpan(reply);
    const calls = original.calls.get('example')!.filter(call => call.callee === 'pattern_scan' && call.offset >= span.beg && call.offset < span.end);
    if (!calls.length) continue;
    const plans = calls.map(call => {
      const cursor = call.args[0];
      const pattern = cursor?.$ === 'Var' ? lineage.get(cursor.i) : undefined;
      if (!pattern) throw Error('Fixture cursor has no source token-pattern lineage');
      return planPatternScanCursorCall(call, lexical, pattern, fileId);
    });
    const index = cursorHelpers.length;
    const cursorName = `fixture_cursor_${index}`, callbackName = `fixture_callback_${index}`;
    const captures = lexicalBodyCaptures(reply, lexical);
    const parameters: ParserParameter[] = captures.map(binding => [binding.quantity, binding.name, binding.id, binding.type, span]);
    const ignoredRanges = calls.flatMap(call => call.args.slice(0, 2).map(argument => {
      if (!argument.s) throw Error('Fixture recursive argument lacks a span');
      return argument.s;
    }));
    const callbackCaptures = lexicalBodyCaptures(reply, lexical, { ignoredRanges });
    const callbackParameters: ParserParameter[] = callbackCaptures.map(binding => [binding.quantity, binding.name, binding.id, binding.type, span]);
    const callbackIds = calls.map((_, callIndex) => -1 - callIndex);
    callbackIds.forEach(id => callbackParameters.push([{ $: 'Lone' }, 'continuation', id, callbackType, span]));

    function render(parameters: ParserParameter[], callback: boolean) {
      let context: BodyRenderContext;
      return renderBody(reply, parameters, {
        book: original.parserBook,
        emitTerminal(term, current) {
          context = current;
          if (!callback) return current.renderTerm(term);
          // Substitute before alpha rendering: cursor/file are deliberately
          // absent from the callback helper's lexical parameter scope.
          const rewritten = replaceTerm(term, node => {
            if (node.$ !== 'App') return;
            const [head, arguments_] = B.term_unapply(node);
            if (head.$ !== 'Ref' || arguments_.length !== 7) return;
            const index = calls.findIndex(call => call.offset === head.s?.beg);
            if (index < 0) return;
            let invocation: B.LTerm = { $: 'Var', k: 'continuation', i: callbackIds[index]! };
            for (const argument of arguments_.slice(2)) invocation = { $: 'App', f: invocation, x: argument };
            return invocation;
          });
          return current.renderTerm(rewritten);
        },
        showTerm(term, names, precedence) {
          if (callback) return B.term_show(term, precedence, names);
          const rewritten = replaceTerm(term, node => {
            if (node.$ !== 'App') return undefined;
            const [head, arguments_] = B.term_unapply(node);
            if (head.$ !== 'Ref' || arguments_.length !== 7) return undefined;
            const callIndex = calls.findIndex(call => call.offset === head.s?.beg);
            if (callIndex < 0) return undefined;
            const call = calls[callIndex]!, plan = plans[callIndex]!;
            const formal = context.binderMap.get(plan.cursor.id)!;
            const rendered = renderPatternScanCursorCall(source, call, { ...plan, formal }, context.binderMap);
            const expression = rendered.source;
            evidence.push({ originalOffset: call.offset, firstArgument: call.args[0]!, cursorFormal: formal,
              remainingArguments: plan.remainingArguments, substitutedArguments: rendered.substitutedArguments,
              astEquivalent: rendered.astEquivalent, directCall: rendered.source, sourceQuantity: plan.cursor.quantity,
              cursorHelper: cursorName, cursorParameterIndex: parameters.findIndex(parameter => parameter[2] === plan.cursor.id),
              helperCallIndex: callIndex });
            // A printer-only atom: its contents are the actual production-rendered
            // call expression, which the native source parser reads normally.
            return { $: 'Ref', k: expression };
          });
          return B.term_show(rewritten, precedence, names);
        },
      });
    }
    const cursor = render(parameters, false), callback = render(callbackParameters, true);
    cursorHelpers.push(`def ${cursorName}(${cursor.parameters}) -> ${cursor.renderTerm(signature.result)}:\n${cursor.body}\n`);
    callbackHelpers.push(`def ${callbackName}(${callback.parameters}) -> ${callback.renderTerm(signature.result)}:\n${callback.body}\n`);
    ownership.push({ cursorHelper: cursorName, callbackHelper: callbackName,
      cursorQuantities: parameters.map(parameter => parameter[0]), callbackQuantities: callbackParameters.map(parameter => parameter[0]),
      cursorCaptureIds: parameters.map(parameter => parameter[2]) });
    cursorPatches.push({ ...span, source: cursorName + '(' + captures.map(binding => binding.name).join(', ') + ')' });
    const callbackActuals = calls.map((call, callIndex) => {
      const plan = plans[callIndex]!;
      const reserved = new Set([...captures.map(binding => binding.name), plan.cursor.name, plan.file.name]);
      const arguments_ = Array.from({ length: 5 }, (_, argumentIndex) => {
        let name = `fixture_next_${argumentIndex}`;
        while (reserved.has(name)) name += '_';
        reserved.add(name); return name;
      });
      return arguments_.map(name => name + ' => ').join('') + `pattern_scan(${plan.cursor.name}, ${plan.file.name}, ${arguments_.join(', ')})`;
    });
    callbackPatches.push({ ...span, source: callbackName + '(' + [...callbackCaptures.map(binding => binding.name), ...callbackActuals].join(', ') + ')' });
  }
  if (!evidence.length) throw Error('Fixture selected no scanner calls');
  function apply(patches: typeof cursorPatches, helpers: string[]) {
    let result = source;
    for (const patch of [...patches].sort((a, b) => b.beg - a.beg)) result = result.slice(0, patch.beg) + patch.source + result.slice(patch.end);
    const owner = result.indexOf('def example(');
    return result.slice(0, owner) + helpers.join('\n') + '\n' + result.slice(owner);
  }
  const cursorSource = apply(cursorPatches, cursorHelpers), callbackSource = apply(callbackPatches, callbackHelpers);
  const cursorGraph = await readParserGraph(cursorSource), callbackGraph = await readParserGraph(callbackSource);
  return { original, cursorSource, callbackSource, cursorGraph, callbackGraph, evidence, ownership };
}
