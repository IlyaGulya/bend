import {createHash} from 'node:crypto';
import type {LTerm, Match, Span} from '../bend2/bend.ts';
import {readParserGraph} from './parser_full_graph.ts';
import type {ParserCall, ParserParameter} from './parser_full_graph.ts';
import {swapMatchSource} from './column_source_swap.ts';

const sha = (text: string) => createHash('sha256').update(text).digest('hex');
type Edit = {beg: number; end: number; before: string; after: string; kind: string};
type Slice = {beg: number; end: number};
const permutation = [2, 1, 0, 3, 4, 5, 6];

/** Split one source invocation/telescope, retaining native coordinates and trivia.
 * AST call offsets identify the invocation; no text search identifies callsites.
 */
function argumentsAt(source: string, offset: number, prefix: string): Slice[] {
  if (!source.startsWith(prefix + '(', offset)) throw Error('Invocation anchor drift');
  const parts: Slice[] = [];
  let start = offset + prefix.length + 1, quote = '', escaped = false;
  const stack = [')'];
  for (let i = start; i < source.length; i++) {
    const c = source[i]!;
    if (quote) {
      if (escaped) escaped = false;
      else if (c === '\\') escaped = true;
      else if (c === quote) quote = '';
      continue;
    }
    if (c === '"' || c === "'") { quote = c; continue; }
    if (['<>', '=>', '->'].includes(source.slice(i, i + 2))) { i++; continue; }
    const opener = '([{<'.indexOf(c);
    if (opener >= 0) { stack.push(')]}>'[opener]!); continue; }
    if (')]}>'.includes(c)) {
      if (stack.pop() !== c) throw Error('Unbalanced invocation at ' + offset);
      if (stack.length === 0) { parts.push(trim(start, i)); return parts; }
    } else if (c === ',' && stack.length === 1) { parts.push(trim(start, i)); start = i + 1; }
  }
  throw Error('Unclosed invocation at ' + offset);
  function trim(beg: number, end: number): Slice {
    while (/\s/.test(source[beg] ?? '') && beg < end) beg++;
    while (/\s/.test(source[end - 1] ?? '') && end > beg) end--;
    if (beg === end) throw Error('Empty invocation argument');
    return {beg, end};
  }
}
function pairEdit(source: string, a: Slice, b: Slice, kind: string): Edit {
  if (a.beg >= a.end || a.end > b.beg || b.beg >= b.end) throw Error('Invalid swap coordinates');
  const before = source.slice(a.beg, b.end);
  const after = source.slice(b.beg, b.end) + source.slice(a.end, b.beg) + source.slice(a.beg, a.end);
  if (before.length !== after.length) throw Error('Swap changed enclosing coordinates');
  return {beg: a.beg, end: b.end, before, after, kind};
}
function apply(source: string, edits: Edit[], inverse = false): string {
  let output = source;
  for (const edit of [...edits].sort((a, b) => b.beg - a.beg)) {
    if (output.slice(edit.beg, edit.end) !== (inverse ? edit.after : edit.before)) throw Error('Edit anchor drift');
    output = output.slice(0, edit.beg) + (inverse ? edit.before : edit.after) + output.slice(edit.end);
  }
  return output;
}
function span(term: {s?: Span}, source: string): Slice {
  if (!term.s || term.s.src !== source) throw Error('Missing canonical native span');
  return {beg: term.s.beg, end: term.s.beg + source.slice(term.s.beg, term.s.end).trimEnd().length};
}
function parameterText(source: string, parameter: ParserParameter, slice: Slice): string {
  const text = source.slice(slice.beg, slice.end);
  const prefix = {Many: '+', Lone: '', None: '~'}[parameter[0].$];
  if (!text.startsWith(prefix + parameter[1] + ':')) throw Error('Quantity/name source mismatch');
  if (parameter[4].beg < slice.beg || parameter[4].end > slice.end) throw Error('Formal AST/source mismatch');
  return text;
}
function callText(source: string, call: ParserCall): string[] {
  const slices = argumentsAt(source, call.offset, 'pattern_scan');
  if (slices.length !== permutation.length || call.args.length !== slices.length) throw Error('Partial or overapplied scanner call');
  call.args.forEach((arg: LTerm, index) => {
    if (!arg.s || arg.s.src !== source) throw Error('Missing actual native span');
    const nativeEnd = arg.s.beg + source.slice(arg.s.beg, arg.s.end).trimEnd().length;
    if (arg.s.beg < slices[index]!.beg || nativeEnd > slices[index]!.end) throw Error('Actual AST/source span mismatch');
  });
  return slices.map(slice => source.slice(slice.beg, slice.end));
}

/** Complete source ABI permutation, not the rejected column-only diagnostic. */
export async function alignedPatternScanSource(source: string) {
  const graph = await readParserGraph(source);
  const body = graph.bodies.get('pattern_scan'), signature = graph.signatures.get('pattern_scan');
  if (body?.$ !== 'Match' || !signature || body.r.length !== 20) throw Error('Frozen scanner shape drift');
  if (signature.parameters.length !== 7 || signature.parameters[0]![1] !== 'tokens' || signature.parameters[2]![1] !== 'mode') throw Error('Scanner formal positions drift');
  const columns = swapMatchSource(source, body);
  const edits: Edit[] = [pairEdit(source, span(body.e[0]!, source), span(body.e[1]!, source), 'scrutinees')];
  body.r.forEach((row, index) => edits.push(pairEdit(source, span(row.p[0]!, source), span(row.p[1]!, source), 'row-' + index)));
  if (apply(source, edits) !== columns.source) throw Error('Native column span swap differs from existing implementation');
  const header = signature.parameters[0]![4].beg;
  const declaration = source.lastIndexOf('def pattern_scan(', header);
  if (declaration < 0) throw Error('Missing scanner declaration');
  const formals = argumentsAt(source, declaration, 'def pattern_scan');
  if (formals.length !== 7) throw Error('Formal source arity drift');
  const originalParameters = signature.parameters.map((parameter, index) => ({name: parameter[1], quantity: parameter[0].$, declaration: parameterText(source, parameter, formals[index]!)}));
  edits.push(pairEdit(source, formals[0]!, formals[2]!, 'formals'));
  const calls = [...graph.calls.values()].flat().filter(call => call.callee === 'pattern_scan');
  const callOffsets = new Set(calls.map(call => call.offset));
  const references = graph.astReferences.filter(site => site.callee === 'pattern_scan');
  if (callOffsets.size !== calls.length || references.length !== calls.length || references.some(site => !callOffsets.has(site.sourceOffset))) throw Error('Scanner reference not audited as a unique fully applied call');
  if (calls.length !== 18 || calls.filter(call => call.caller === 'pattern_scan').length !== 16) throw Error('Frozen scanner call count drift');
  const callAudit = calls.map(call => {
    const args = callText(source, call), slices = argumentsAt(source, call.offset, 'pattern_scan');
    edits.push(pairEdit(source, slices[0]!, slices[2]!, 'call-' + call.offset));
    return {caller: call.caller, line: call.line, column: call.column, offset: call.offset, recursive: call.caller === 'pattern_scan', original: args, transformed: permutation.map(index => args[index]!)};
  });
  const ordered = [...edits].sort((a, b) => a.beg - b.beg);
  for (let i = 1; i < ordered.length; i++) if (ordered[i - 1]!.end > ordered[i]!.beg) throw Error('Overlapping diagnostic edits');
  const changed = apply(source, edits);
  if (apply(changed, edits, true) !== source) throw Error('Aligned source permutation is not byte-invertible');
  let previous = 0;
  for (const edit of ordered) {
    if (changed.slice(previous, edit.beg) !== source.slice(previous, edit.beg)) throw Error('Unrelated source drift');
    previous = edit.end;
  }
  if (changed.slice(previous) !== source.slice(previous)) throw Error('Unrelated source tail drift');
  const transformed = await readParserGraph(changed);
  const newSignature = transformed.signatures.get('pattern_scan')!, newBody = transformed.bodies.get('pattern_scan') as Match;
  const newFormals = argumentsAt(changed, declaration, 'def pattern_scan');
  const transformedParameters = newSignature.parameters.map((parameter, index) => ({name: parameter[1], quantity: parameter[0].$, declaration: parameterText(changed, parameter, newFormals[index]!)}));
  if (JSON.stringify(transformedParameters) !== JSON.stringify(permutation.map(index => originalParameters[index]))) throw Error('Parameter quantity/type permutation drift');
  if (JSON.stringify(transformed.definitions) !== JSON.stringify(graph.definitions) || JSON.stringify(transformed.edges) !== JSON.stringify(graph.edges)) throw Error('Definition/dependency drift');
  const newCalls = [...transformed.calls.values()].flat().filter(call => call.callee === 'pattern_scan');
  if (newCalls.length !== calls.length) throw Error('Transformed call count drift');
  for (const audit of callAudit) {
    const call = newCalls.find(call => call.offset === audit.offset && call.caller === audit.caller);
    if (!call || JSON.stringify(callText(changed, call)) !== JSON.stringify(audit.transformed)) throw Error('Actual permutation audit failed');
  }
  const newReferences = transformed.astReferences.filter(site => site.callee === 'pattern_scan');
  if (newReferences.length !== newCalls.length || newReferences.some(site => !callOffsets.has(site.sourceOffset))) throw Error('Transformed reference audit failed');
  if (newBody.$ !== 'Match' || newBody.r.length !== 20) throw Error('Transformed row count drift');
  const rows = columns.audit.rows.map((row, index) => {
    const newPatterns = newBody.r[index]!.p.map(pattern => {const s = span(pattern, changed); return changed.slice(s.beg, s.end);});
    if (JSON.stringify(newPatterns) !== JSON.stringify(row.transformed)) throw Error('Pattern row priority/order drift');
    const {beg, end} = row.bodyOffsets;
    const recursiveEdits = edits.filter(edit => edit.kind.startsWith('call-') && edit.beg >= beg && edit.end <= end);
    const expected = apply(source, recursiveEdits).slice(beg, end), actual = changed.slice(beg, end);
    if (actual !== expected) throw Error('Row body changed beyond recursive actual permutation');
    return {index, originalPatterns: row.original, transformedPatterns: row.transformed, originalBodySha256: row.bodySha256, transformedBodySha256: sha(actual), recursiveActualSwaps: recursiveEdits.length, bodyPreservedModuloRecursiveActuals: true};
  });
  return {source: changed, graph: transformed, audit: {status: 'SOURCE_AUDIT_PASS', originalSha256: sha(source), transformedSha256: sha(changed), permutation, originalParameters, transformedParameters, scrutinees: columns.audit.scrutinees, rowCount: 20, rows, calls: callAudit, callCount: calls.length, recursiveCallCount: 16, allReferencesFullyAppliedAndAudited: true, rowOrderUnchanged: true, quantitiesAndTypesPreserved: true, inverseByteExact: true, unrelatedBytesIdentical: true, definitionAndDependencyGraphUnchanged: true, editCount: edits.length}};
}
