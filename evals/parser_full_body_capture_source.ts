/** Fixture-only match-row extraction, using the production capture seam.
 * Bodies/types are printed with the existing binder-ID renderer; only the row
 * body span is replaced. No fixture-name cases or hand-selected capture lists.
 */
import * as B from '../bend2/bend.ts';
import { captureQuantityPrefix, lexicalBodyCaptures } from './parser_full_lexical_body_capture.ts';
import { renderBody } from './parser_full_body_render.ts';
import { readParserGraph, type ParserGraph, type ParserParameter } from './parser_full_graph.ts';
import { LexicalTypes } from './parser_full_type_env.ts';

/** Row paths descend through Local bodies and then select successive Matches. */
export function fixtureRow(graph: ParserGraph, path: readonly number[], owner = 'example'): B.Case {
  let body = graph.bodies.get(owner);
  let selected: B.Case | undefined;
  for (const index of path) {
    while (body?.$ === 'Local') body = body.f;
    if (body?.$ !== 'Match' || !body.r[index]) throw Error('Invalid fixture match-row path');
    selected = body.r[index]!;
    body = selected.f;
  }
  if (!selected) throw Error('A fixture extraction requires a row');
  return selected;
}

export async function extractFixtureRow(source: string, path: readonly number[]) {
  const original = await readParserGraph(source);
  const signature = original.signatures.get('example')!;
  const body = original.bodies.get('example')!;
  const lexical = new LexicalTypes(original.parserBook, original.signatures);
  lexical.indexBody(body, signature.parameters, signature.result);
  const row = fixtureRow(original, path);
  const captures = lexicalBodyCaptures(row.f, lexical);
  const parameters: ParserParameter[] = captures.map(binding => [
    binding.quantity, binding.name, binding.id, binding.type,
    { file: row.p[0]!.s!.file, beg: 0, end: 0 },
  ]);
  const rendered = renderBody(row.f, parameters, { book: original.parserBook });
  const telescope = captures.map(binding =>
    `${captureQuantityPrefix(binding.quantity)}${rendered.binderMap.get(binding.id)!}: ${rendered.renderTerm(binding.type)}`
  ).join(', ');
  const helper = 'extracted_fixture_row';
  if (original.definitions.includes(helper)) throw Error('Fixture helper name collision');

  // Each containing match supplies the exclusive boundary of its last row;
  // this handles nested matches without truncating their descendant rows.
  const ownerOffset = source.indexOf('def example(');
  const nextDefinition = source.indexOf('\ndef ', ownerOffset);
  let end = nextDefinition < 0 ? source.length : nextDefinition + 1;
  let current: B.Body = body;
  for (const index of path) {
    while (current.$ === 'Local') current = current.f;
    if (current.$ !== 'Match') throw Error('Fixture row no longer belongs to a match');
    const sibling = current.r[index + 1];
    if (sibling) end = source.lastIndexOf('\n', sibling.p[0]!.s!.beg - 1) + 1;
    current = current.r[index]!.f;
  }
  const patternEnd = Math.max(...row.p.map(pattern => pattern.s!.end));
  const newline = source.indexOf('\n', patternEnd);
  if (newline < 0) throw Error('Fixture row has no body line');
  const begin = newline + 1;
  const indent = source.slice(begin).match(/^[ \t]*/)![0];
  const actuals = captures.map(binding => binding.name).join(', ');
  const transformed = source.slice(0, ownerOffset)
    + `def ${helper}(${telescope}) -> ${rendered.renderTerm(signature.result)}:\n${rendered.body}\n\n`
    + source.slice(ownerOffset, begin)
    + `${indent}${helper}(${actuals})\n`
    + source.slice(end);
  const graph = await readParserGraph(transformed);
  return { source: transformed, graph, original, captures };
}
