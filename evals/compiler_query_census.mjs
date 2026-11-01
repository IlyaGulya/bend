import {types} from 'node:util';

// Passive argument identity only. In particular, NfClosure is Data containing
// body + env, not an executable JS closure. Nothing here normalizes or quotes.
export const QUERY_CENSUS_SCHEMA_VERSION = 1;
const FIELDS = Object.freeze({
  nf: Object.freeze(['context', 'descriptor', 'env', 'level', 'fuel']),
  reach: Object.freeze(['context', 'descriptor', 'env', 'target', 'seen', 'fuel']),
});
const MAX_NAT = 10n ** 4096n;
const own = (value, key) => {
  const field = Object.getOwnPropertyDescriptor(value, key);
  if (!field || !Object.hasOwn(field, 'value')) throw new ObservationFailure('unsupported', 'accessor-or-missing-field');
  return field.value;
};
class ObservationFailure extends Error {
  constructor(status, reason) { super(reason); this.status = status; this.reason = reason; }
}
const unsupported = reason => { throw new ObservationFailure('unsupported', reason); };
const censored = reason => { throw new ObservationFailure('censored', reason); };
function plain(value, arrays = false) {
  if (value === null || typeof value !== 'object') unsupported('non-data-object');
  if (types.isProxy(value)) unsupported('proxy');
  const array = Array.isArray(value), prototype = Object.getPrototypeOf(value);
  if (array && !arrays) unsupported('unexpected-array');
  if (prototype !== null && prototype !== (array ? Array.prototype : Object.prototype)) unsupported('unknown-object-representation');
  return array;
}
function integer(options, name, fallback, ceiling) {
  const descriptor = Object.getOwnPropertyDescriptor(options, name);
  if (descriptor && !Object.hasOwn(descriptor, 'value')) throw Error('Query census option accessor: ' + name);
  const value = descriptor?.value ?? fallback;
  if (!Number.isSafeInteger(value) || value < 1 || value > ceiling) throw Error('Invalid query census limit: ' + name);
  return value;
}
const counters = () => ({total: 0, classified: 0, exactDistinct: 0, exactRepeats: 0, unsupported: 0, censored: 0});

/**
 * The caller authenticates producer, site, constructor and source declarations;
 * fields contains EXACTLY FIELDS[kind], optionally with the raw payload's own
 * string $ constructor. The caller authenticates that transport constructor;
 * it is not an additional semantic query argument.
 * provenance is an optional flat own-data record of strings, booleans, null,
 * and exact integers. It is copied, bounded and reported, never authenticated
 * here. Do not pass a native snapshot or an entire manifest as provenance.
 *
 * immutableData:true asserts the native language's immutable Data contract and
 * enables bounded weak memoization even when JS objects are not frozen. With
 * the safe default false, only transitively frozen subgraphs are memoized.
 * Mutating a graph after asserting immutableData invalidates the measurement.
 *
 * All caps stop classification permanently, without affecting source execution.
 * observe returns {status, reason?}; report contains no native argument objects.
 */
export function createQueryCensus(options = {}) {
  plain(options);
  const immutableOption = Object.getOwnPropertyDescriptor(options, 'immutableData');
  if (immutableOption && (!Object.hasOwn(immutableOption, 'value') || typeof immutableOption.value !== 'boolean'))
    throw Error('Query census immutableData must be a boolean');
  const config = Object.freeze({
    maxNodes: integer(options, 'maxNodes', 500000, 8000000),
    maxQueries: integer(options, 'maxQueries', 100000, 1000000),
    maxBytes: integer(options, 'maxBytes', 134217728, 1073741824),
    maxWorkPerQuery: integer(options, 'maxWorkPerQuery', 2000000, 16000000),
    maxWeakEntries: integer(options, 'maxWeakEntries', 1000000, 8000000),
    maxFieldsPerNode: integer(options, 'maxFieldsPerNode', 65536, 1000000),
    maxStringLength: integer(options, 'maxStringLength', 65536, 1000000),
    maxProvenance: integer(options, 'maxProvenance', 32, 256),
    immutableData: immutableOption?.value ?? false,
  });
  const interned = new Map(), memo = new WeakMap(), contexts = new WeakMap(), provenances = new Map();
  const state = Object.fromEntries(Object.entries(FIELDS).map(([kind, fields]) => [kind, {
    counts: counters(), prefix: {classified: 0, exactDistinct: 0, exactRepeats: 0},
    queries: new Set(), components: Object.fromEntries(fields.map(field => [field, new Set()])),
    without: Object.fromEntries(fields.map(field => [field, new Set()])),
    contextStructures: new Set(), contextObjects: new Set(),
  }]));
  const reasons = {unsupported: new Map(), censored: new Map()};
  let retainedBytes = 0, weakEntries = 0, nextContext = 1, distinctQueries = 0;
  let total = 0, unknownKind = 0, stopReason = null, prefixOpen = true, prefixObservations = 0;
  let work = 0, totalWork = 0, peakWork = 0, memoHits = 0, scannedObjects = 0;
  const spend = (amount = 1) => {
    if (amount > config.maxWorkPerQuery - work) censored('maxWorkPerQuery');
    work += amount;
  };
  const reserve = amount => {
    if (amount > config.maxBytes - retainedBytes) censored('maxBytes');
    retainedBytes += amount;
  };
  const cost = key => 64 + key.length * 2;
  const text = value => {
    if (value.length > config.maxStringLength) censored('maxStringLength');
    spend(value.length + 1);
    return value;
  };
  const signature = parts => {
    // Only freshly constructed, dense arrays of validated scalar strings/IDs:
    // no target toJSON, getters, callbacks or recursive target serialization.
    spend(parts.length);
    const result = JSON.stringify(parts);
    if (result.length * 2 > config.maxBytes) censored('maxBytes');
    return result;
  };
  const intern = key => {
    const found = interned.get(key);
    if (found !== undefined) return found;
    if (interned.size >= config.maxNodes) censored('maxNodes');
    reserve(cost(key));
    const id = interned.size + 1;
    interned.set(key, id);
    return id;
  };
  const primitive = value => {
    if (typeof value === 'string') return intern(signature(['string', text(value)]));
    if (typeof value === 'boolean') return intern(value ? 'bool:true' : 'bool:false');
    if (value === null) return intern('null');
    if (typeof value === 'number') {
      if (!Number.isSafeInteger(value) || value < 0 || Object.is(value, -0)) unsupported('unsafe-or-non-natural-number');
      return intern('nat:' + value);
    }
    if (typeof value === 'bigint') {
      if (value < 0n) unsupported('negative-natural');
      if (value >= MAX_NAT) censored('natural-digit-limit');
      const digits = value.toString(); spend(digits.length);
      return intern('nat:' + digits);
    }
    unsupported(typeof value === 'function' ? 'function' : 'unsupported-scalar');
  };
  function keys(value) {
    const names = Reflect.ownKeys(value);
    if (names.length > config.maxFieldsPerNode) censored('maxFieldsPerNode');
    spend(names.length);
    for (const name of names) {
      if (typeof name !== 'string') unsupported('symbol-field');
      text(name);
    }
    return names;
  }
  function shape(value) {
    const array = plain(value, true);
    if (array) {
      const length = own(value, 'length');
      if (!Number.isSafeInteger(length) || length < 0) unsupported('invalid-array-length');
      if (length + 1 > config.maxFieldsPerNode) censored('maxFieldsPerNode');
      if (length > config.maxWorkPerQuery - work) censored('maxWorkPerQuery');
      const names = keys(value);
      if (names.length !== length + 1) unsupported('sparse-or-decorated-array');
      // Checking every expected index also rejects equal-count decorations.
      for (let index = 0; index < length; index++) own(value, String(index));
      return {names: Array.from({length}, (_, index) => String(index)), prefix: 'array'};
    }
    const names = keys(value).sort();
    const tag = own(value, '$');
    if (typeof tag !== 'string' || tag.length === 0) unsupported('untagged-data-record');
    // Full qualified tag and every field participate. No guessed provider names,
    // declaration deduplication, list reordering, or Base.Map flattening.
    for (const name of names) own(value, name);
    return {names, prefix: 'record'};
  }
  function structural(root) {
    const active = new WeakSet();
    const stack = [{value: root, entered: false}];
    let result;
    while (stack.length) {
      const frame = stack[stack.length - 1];
      if (!frame.entered) {
        spend();
        const value = frame.value;
        if (value === null || typeof value !== 'object') {
          finish(primitive(value), true); continue;
        }
        // Reject before any reflection or cached lookup that could conceal a
        // proxy. Active ancestors are cycles, shared completed children are not.
        if (types.isProxy(value)) unsupported('proxy');
        if (active.has(value)) unsupported('cycle');
        const cached = memo.get(value);
        if (cached !== undefined) { memoHits++; finish(cached, true); continue; }
        const {names, prefix} = shape(value);
        scannedObjects++;
        active.add(value);
        frame.entered = true; frame.names = names; frame.index = 0;
        frame.parts = [prefix]; frame.stable = config.immutableData || Object.isFrozen(value);
      }
      if (frame.index < frame.names.length) {
        const name = frame.names[frame.index++];
        frame.parts.push(name);
        stack.push({value: own(frame.value, name), entered: false});
      } else {
        const id = intern(signature(frame.parts));
        active.delete(frame.value);
        if (frame.stable) {
          if (weakEntries >= config.maxWeakEntries) censored('maxWeakEntries');
          reserve(48); weakEntries++; memo.set(frame.value, id);
        }
        finish(id, frame.stable);
      }
    }
    return result;
    function finish(id, stable) {
      stack.pop();
      if (stack.length) {
        const parent = stack[stack.length - 1];
        parent.parts.push(id); parent.stable &&= stable;
      } else result = id;
    }
  }
  function provenanceRecord(value) {
    if (value === undefined) return null;
    plain(value);
    const names = keys(value).sort();
    if (names.length > 32) censored('provenance-field-limit');
    const copy = Object.create(null), parts = [];
    for (const name of names) {
      const item = own(value, name);
      if (typeof item === 'string') { text(item); copy[name] = item; parts.push(name, 'string', item); }
      else if (item === null || typeof item === 'boolean') { copy[name] = item; parts.push(name, item); }
      else if ((typeof item === 'number' && Number.isSafeInteger(item) && item >= 0 && !Object.is(item, -0)) || (typeof item === 'bigint' && item >= 0n && item < MAX_NAT)) {
        const digits = String(item); text(digits);
        // JSON-safe copy preserves the incoming number/bigint representation.
        copy[name] = typeof item === 'bigint' ? {type: 'bigint', decimal: digits} : item;
        parts.push(name, typeof item, digits);
      } else unsupported('unsupported-provenance-field');
    }
    const key = signature(parts);
    let row = provenances.get(key);
    if (!row) {
      if (provenances.size >= config.maxProvenance) censored('maxProvenance');
      reserve(cost(key) * 2 + 128);
      row = {value: copy, observations: 0, classified: 0}; provenances.set(key, row);
    }
    row.observations++;
    return row;
  }
  function classify(kind, fields, provenance) {
    plain(fields);
    const expected = FIELDS[kind], names = keys(fields);
    const hasTag = names.includes('$');
    if (names.length !== expected.length + Number(hasTag) || expected.some(name => !names.includes(name))) unsupported('query-field-set');
    if (hasTag) {
      const constructor = own(fields, '$');
      if (typeof constructor !== 'string' || constructor.length === 0) unsupported('invalid-payload-constructor');
      text(constructor);
    }
    const values = expected.map(name => own(fields, name));
    for (const name of kind === 'nf' ? ['level', 'fuel'] : ['fuel']) {
      const value = values[expected.indexOf(name)];
      if (!((typeof value === 'number' && Number.isSafeInteger(value) && value >= 0 && !Object.is(value, -0)) || (typeof value === 'bigint' && value >= 0n))) unsupported('invalid-query-natural');
    }
    const provenanceRow = provenanceRecord(provenance);
    const context = values[0]; plain(context);
    const ids = values.map(structural), contextStructure = ids[0];
    let contextId = contexts.get(context);
    if (contextId === undefined) {
      if (weakEntries >= config.maxWeakEntries) censored('maxWeakEntries');
      reserve(48); weakEntries++; contextId = nextContext++; contexts.set(context, contextId);
    }
    // Pair object identity with current full structure. With immutableData:false,
    // even a mutated, nonmemoized context cannot accidentally prove a repeat.
    ids[0] = 'context:' + contextId + ':' + contextStructure;
    const stats = state[kind], key = signature(ids), repeated = stats.queries.has(key);
    if (!repeated && distinctQueries >= config.maxQueries) censored('maxQueries');
    const additions = [];
    const add = (set, value) => { if (!set.has(value)) additions.push([set, value]); };
    add(stats.queries, key); add(stats.contextStructures, contextStructure);
    add(stats.contextObjects, contextId);
    for (let index = 0; index < expected.length; index++) {
      add(stats.components[expected[index]], ids[index]);
      add(stats.without[expected[index]], signature(ids.filter((_, at) => at !== index)));
    }
    // Commit all classification/projection entries together. A cap never becomes
    // a spurious distinct query or a partially updated variation measurement.
    let bytes = 0;
    for (const [, value] of additions) bytes += typeof value === 'string' ? cost(value) : 48;
    reserve(bytes);
    for (const [set, value] of additions) set.add(value);
    stats.counts.classified++;
    if (repeated) stats.counts.exactRepeats++;
    else { stats.counts.exactDistinct++; distinctQueries++; }
    if (provenanceRow) provenanceRow.classified++;
    if (prefixOpen) {
      prefixObservations++;
      stats.prefix.classified++;
      stats.prefix[repeated ? 'exactRepeats' : 'exactDistinct']++;
    }
    return {status: 'classified', repeated};
  }
  function observe(kind, fields, provenance) {
    total++;
    const known = typeof kind === 'string' && Object.hasOwn(FIELDS, kind);
    if (known) state[kind].counts.total++; else unknownKind++;
    work = 0;
    try {
      if (stopReason !== null) censored(stopReason);
      if (!known) unsupported('unknown-query-kind');
      return classify(kind, fields, provenance);
    } catch (error) {
      if (!(error instanceof ObservationFailure)) throw error;
      prefixOpen = false;
      if (error.status === 'censored') stopReason ??= error.reason;
      if (known) state[kind].counts[error.status]++;
      const counts = reasons[error.status]; counts.set(error.reason, (counts.get(error.reason) ?? 0) + 1);
      return {status: error.status, reason: error.reason};
    } finally {
      totalWork += work; peakWork = Math.max(peakWork, work);
    }
  }
  function report() {
    return {
      schemaVersion: QUERY_CENSUS_SCHEMA_VERSION, diagnosticOnly: true, acceptanceEvidence: false,
      status: stopReason !== null ? 'censored' : reasons.unsupported.size ? 'incomplete' : 'complete',
      limits: {...config}, stopReason, total, unknownKind,
      fullyClassifiedPrefix: {observations: prefixObservations, endedAtFirstIncompleteObservation: !prefixOpen,
        nf: {...state.nf.prefix}, reach: {...state.reach.prefix}},
      kinds: Object.fromEntries(Object.entries(state).map(([kind, stats]) => [kind, {
        ...stats.counts,
        componentDistinct: Object.fromEntries(Object.entries(stats.components).map(([field, values]) => [field, values.size])),
        structurallyDistinctContexts: stats.contextStructures.size,
        contextObjectCount: stats.contextObjects.size,
        projections: Object.fromEntries(Object.entries(stats.without).map(([field, values]) => [field, {
          omittedField: field, distinct: values.size, additionalMerges: stats.queries.size - values.size,
          diagnosticOnly: true, cacheEquivalenceClaim: false,
        }])),
      }])),
      unsupportedReasons: Object.fromEntries(reasons.unsupported), censoredReasons: Object.fromEntries(reasons.censored),
      provenance: [...provenances.values()].map(row => ({
        value: Object.fromEntries(Object.entries(row.value).map(([key, value]) => [key,
          value !== null && typeof value === 'object' ? {...value} : value])),
        observations: row.observations, classified: row.classified,
      })),
      resources: {internedNodes: interned.size, distinctQueries, weakEntriesInserted: weakEntries,
        contextsAssigned: nextContext - 1, accountedRetainedBytes: retainedBytes, totalWork, peakWorkPerQuery: peakWork,
        memoHits, scannedObjects},
      identity: {
        exactWithin: 'Complete structural arguments plus context object identity and context structure; counted classified observations only.',
        context: 'Object identity is conservative: distinct query counts upper-bound structurally scoped argument classes across context copies; repeats prove equality within the observed context identity.',
        structure: 'Full qualified tags and all own-data fields; array/list order, duplicates, Base.Map tree structure, semantic closure bodies/environments and binder levels retained. No declaration authority is rewritten.',
        numbers: 'Nonnegative safe integer numbers and equal bigint values share Nat identity. Unsafe, fractional, negative and negative-zero numbers are unsupported.',
        immutability: config.immutableData ? 'Caller asserts all native Data and arrays remain immutable; weak memoization relies on that contract.' : 'Only transitively frozen subgraphs are weakly memoized; unfrozen Data is rescanned.',
      },
      limitations: [
        'Caller-supplied provenance is preserved, not independently authenticated by this module.',
        'No evaluation, normalization, quotation, NF idempotence, cache safety or absence of additional semantic sharing is established.',
        'Few exact repeats cannot refute semantic or subexpression sharing: unused environment entries, alpha equivalence and context copies are deliberately not quotiented out.',
        'Omitting context, fuel, env, level, descriptor, target or seen is a diagnostic projection only. Reach seen remains ordered and target participates in exact identity.',
        'Different Base.Map tree shapes and list-versus-array encodings remain conservatively distinct; unknown object representations are unsupported, never stringified.',
        'Unsupported observations are excluded. Exact totals describe the classified subset; fullyClassifiedPrefix stops at the first unsupported or censored observation.',
        'Any cap permanently stops classification, including known repeats. Partial intern/cache entries may remain but never increase classified/distinct counts.',
        'Byte accounting bounds retained signature payloads and charges per-entry overhead; it is not a JS heap/RSS measurement. Reflection can allocate one own-key array before its size is checked; the external resource guard remains required.',
        'Weak-entry counts are cumulative insertions, not live retained native objects; no query or report holds native values strongly.',
      ],
    };
  }
  return Object.freeze({observe, report});
}
