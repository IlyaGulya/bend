import {createHash} from 'node:crypto';

// Diagnostic only. No arena read, semantic operation, owner retention or FIR mutation.
const LIMIT = 32768;
const tag = x => typeof x?.$ === 'string' ? x.$.split('.').at(-1) : null;
let base, rows = [], byPath = new Map(), status = 'NOT_OBSERVED';
let resolutionRows = [], firstResolution = new Map(), controlFailures = [], collapseFailures = [];
const digest = x => createHash('sha256').update(JSON.stringify(x)).digest('hex');
function scalar(x, name) {
  if (typeof x !== 'number' || !Number.isInteger(x) || x < 0 || x > 4294967295) throw Error('Non-native U32 scalar ' + name);
  return x;
}
// Nat fields are distinct from U32 handles/payloads. The genuine R12 image
// uses number arithmetic with the 2^48-1 immediate bound; the existing closure
// observer also admits bigint Nat carriers. Convert only explicitly Nat roles.
function natural(x, name) {
  if (typeof x === 'bigint') {
    if (x < 0n || x > 281474976710655n) throw Error('Out-of-range Nat ' + name);
    return Number(x);
  }
  if (typeof x !== 'number' || !Number.isSafeInteger(x) || x < 0 || x > 281474976710655) throw Error('Non-native Nat ' + name);
  return x;
}
function text(x, name) {
  if (typeof x !== 'string') throw Error('Non-native string ' + name);
  return x;
}
function each(xs, fn) {
  let n = 0;
  for (; tag(xs) === 'Con'; xs = xs.tail) {
    if (++n > LIMIT) throw Error('N07 list cutoff');
    fn(xs.head, n - 1);
  }
  if (tag(xs) !== 'Nil') throw Error('N07 unsupported list carrier');
}
function mapped(xs, fn) { const out = []; each(xs, x => out.push(fn(x))); return out; }
function binding(x) {
  if (tag(x) !== 'CheckedBinding') throw Error('N07 binding carrier');
  return {quantity: tag(x.quantity), ty: scalar(x.ty, 'binding.ty'), type_depth: natural(x.type_depth, 'binding.type_depth')};
}
function symbol(x) {
  if (tag(x) !== 'Symbol') throw Error('N07 symbol carrier');
  return {owner: text(x.owner, 'symbol.owner'), local: text(x.local, 'symbol.local'), kind: tag(x.kind), signature: scalar(x.signature, 'signature')};
}
function optional(x, fn) {
  if (tag(x) === 'None') return null;
  if (tag(x) !== 'Some') throw Error('N07 optional carrier');
  return fn(x.value);
}
function pattern(x, depth = 0) {
  if (depth > 256) throw Error('N07 pattern cutoff');
  if (tag(x) === 'CheckedVariable') return {variant: tag(x), pattern: scalar(x.pattern, 'pattern'), binding: binding(x.binding)};
  if (tag(x) !== 'CheckedConstructor') throw Error('N07 pattern carrier');
  return {variant: tag(x), pattern: scalar(x.pattern, 'pattern'), symbol: symbol(x.symbol), layout: mapped(x.layout, binding), fields: mapped(x.fields, y => pattern(y, depth + 1))};
}
function walk(x, definition, path, depth = 0) {
  if (depth > 256 || rows.length >= LIMIT) throw Error('N07 occurrence cutoff');
  const row = {definition, path, variant: tag(x), term: scalar(x.term, 'term'), ty: scalar(x.ty, 'ty')};
  const children = [];
  switch (row.variant) {
    case 'TypedOccurrence':
      row.formal = optional(x.formal, tag); row.symbol = optional(x.symbol, symbol);
      row.bindings = mapped(x.bindings, binding);
      each(x.children, (child, i) => children.push([child, 'children/' + i]));
      break;
    case 'LocalReferenceOccurrence':
      row.binding = binding(x.binding); row.value = scalar(x.value, 'semantic value');
      row.valueRole = 'semantic-substitution-not-runtime-operand';
      break;
    case 'ScalarOccurrence':
      row.symbol = symbol(x.symbol); row.symbols = mapped(x.symbols, symbol);
      row.bits = scalar(x.bits, 'bits'); row.bitsRole = 'payload-not-handle';
      break;
    case 'StringOccurrence':
      row.symbols = mapped(x.symbols, symbol);
      row.chars = mapped(x.chars, n => scalar(n, 'char')); row.charsRole = 'payload-not-handles';
      break;
    case 'CaseOccurrence':
      row.patterns = mapped(x.patterns, pattern); children.push([x.body, 'body']);
      break;
    case 'LocalOccurrence':
      row.patterns = mapped(x.patterns, pattern);
      each(x.values, (child, i) => children.push([child, 'values/' + i]));
      children.push([x.body, 'body']);
      break;
    default: throw Error('N07 unknown occurrence ' + row.variant);
  }
  rows.push(row); byPath.set(definition + ':' + path, row);
  for (const [child, edge] of children) walk(child, definition, path + '/' + edge, depth + 1);
}
export function instrument(source, context) {
  base = context.repository + '/bend2/base.bend';
  return {source, metadata: {kind: 'passive-published-occurrence-scan', imageUnchanged: true, limit: LIMIT, ownerRetained: false, lowerResolutionHook: 'optional onLowerResolution; absent means STOP'}};
}
export function onPhase(name, value) {
  if (name !== 'check') return;
  if (tag(value) === 'CheckFailure') { status = 'PRODUCER_REJECTED'; return; }
  if (tag(value) !== 'CheckSuccess' || tag(value.program) !== 'CheckedProgram') throw Error('N07 checked carrier');
  status = 'SCANNING';
  each(value.program.modules, loaded => {
    const module = loaded.module;
    if (module.path === base) return;
    each(module.declarations, top => {
      if (tag(top) !== 'DefTop') return;
      const def = top.definition;
      if (tag(def.checked) === 'Some') walk(def.checked.value, text(loaded.namespace, 'namespace') + '::' + text(def.key, 'key'), 'root');
      else if (tag(def.checked) !== 'None') throw Error('N07 checked optional carrier');
    });
  });
  status = 'OBSERVED_PUBLISHED_OCCURRENCES';
}
function slot(x) {
  if (x.erased === true) return {erased: true};
  if (x.erased !== false) throw Error('N07 explicit slot erasure required');
  return {erased: false, owner: scalar(x.owner, 'slot.owner'), identity: scalar(x.identity, 'slot.identity')};
}
function matches(a, b) {
  return !!a && !!b && a.erased === b.erased && (a.erased || a.owner === b.owner && a.identity === b.identity);
}
// Parent may invoke only at the actual variable/resolve boundary, with scalar
// data extracted while borrowing the current frame. Never substitute this
// diagnostic result back into a compiler call. Event paths must identify the
// originating published occurrence, not call counts or guessed term handles.
export function onLowerResolution(event) {
  if (resolutionRows.length >= LIMIT) throw Error('N07 resolution cutoff');
  const key = text(event.definition, 'definition') + ':' + text(event.path, 'path');
  const occurrence = byPath.get(key);
  const term = scalar(event.term, 'resolution.term');
  if (!occurrence || occurrence.term !== term) throw Error('N07 resolution lacks published occurrence provenance');
  const index = natural(event.index, 'lexical index');
  if (!Array.isArray(event.slots) || event.slots.length > LIMIT) throw Error('N07 lexical environment cutoff');
  const slots = event.slots.map(slot), selected = slot(event.selected);
  const row = {key, term, index, slots, selected};
  resolutionRows.push(row);
  if (!matches(slots[index], selected)) controlFailures.push({key, invariant: 'selected-owner-identity-equals-current-lexical-slot'});
  const previous = firstResolution.get(term);
  if (!previous) firstResolution.set(term, row);
  else if (previous.key !== key && !matches(slots[index], previous.selected)) collapseFailures.push({key, first: previous.key, term, invariant: 'term-only-diagnostic-facts-resolve-outside-current-lexical-slot'});
}
export function snapshot() {
  const first = new Map(), different = [], facts = row => {
    const {definition, path, ...rest} = row; return JSON.stringify(rest);
  };
  for (const row of rows) {
    const prior = first.get(row.term);
    if (!prior) first.set(row.term, row);
    else if (facts(prior) !== facts(row)) different.push({term: row.term, first: prior.definition + ':' + prior.path, second: row.definition + ':' + row.path});
  }
  return {schemaVersion: 1, status, coverageClaim: 'NO_CONSUMER_PRESERVATION_PROOF', rows, rowsSha256: digest(rows), sharedTermDifferentFacts: different,
    diagnosticMutation: {kind: 'first-resolution-facts-per-term-only', mutatesFIR: false, resolutionRows, controlFailures, collapseFailures,
      verdict: !resolutionRows.length ? 'STOP_NO_ACTUAL_LOWERING_HOOK' : controlFailures.length ? 'STOP_CONTROL_INVARIANT' : !different.length ? 'STOP_NO_SHARED_CONTEXTUAL_TERM' : !collapseFailures.length ? 'STOP_MUTATION_INERT' : 'DISTINGUISHING_INVARIANT_OBSERVED_REQUIRES_EXECUTED_TARGET_TRACES'},
    bounds: {maxOccurrences: LIMIT, maxDepth: 256}, payloadPolicy: 'Only schema-declared handles; bits/chars are never edges', runtimeOracle: 'Parent must join this exact checker/emitter report to authenticated C and JS executions and expected stdout; no GO from this snapshot alone'};
}
