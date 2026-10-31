import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { createHash } from 'node:crypto';

const HOOK = '__bendAllNormalizationAssembly';
const IMAGE = 'checkpoints/local2039g24r12/bootstrap.json.cases/stage-one.js';
const SHA = '85aff9e534c18b4a1d6acac5f3237571dabc58f2c1a75a7ea2040f1c477ab60e';
let state;
const escape = s => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const hash = s => createHash('sha256').update(s).digest('hex');

function observer() {
  const counts = Object.create(null), tables = new Map(), tableChars = new Map(), identities = new WeakMap();
  const postBlocks = new WeakMap(), postOps = new WeakMap();
  let nextId = 0, entries = 0, chars = 0, epoch = 0, serial = 0;
  const events = [], indexExamples = [];
  const limits = { entries: 120000, keyChars: 12000000, perMetricKeys: 2048, perMetricChars: 524288, structuralRequests: 4096, structuralNodes: 2048, structuralDepth: 64, structuralChars: 32768 };
  let structuralAttempts = 0, structuralNodes = 0;
  function add(name, n = 1) { counts[name] = (counts[name] || 0) + n; }
  function id(x) {
    if (x !== null && (typeof x === 'object' || typeof x === 'function')) {
      let n = identities.get(x);
      if (!n) { n = ++nextId; identities.set(x, n); }
      return `o${n}`;
    }
    if (typeof x === 'bigint') return `bigint:${x}`;
    if (typeof x === 'number') return `number:${Object.is(x, -0) ? '-0' : x}`;
    return `${typeof x}:${JSON.stringify(x)}`;
  }
  const envId = x => x && x.$ === 'Nil' ? 'Nil' : id(x);
  function tuple(xs) { return JSON.stringify(xs); }
  function seen(name, key, detail) {
    let table = tables.get(name);
    if (!table) { table = new Map(); tables.set(name, table); }
    add(`${name}.requests`);
    const old = table.get(key);
    if (old !== undefined) {
      add(`${name}.repeated`);
      if (detail && indexExamples.length < 32) indexExamples.push({ metric: name, first: old, again: detail });
      return true;
    }
    const heldChars = tableChars.get(name) || 0;
    if (table.size >= limits.perMetricKeys || heldChars + key.length > limits.perMetricChars || entries >= limits.entries || chars + key.length > limits.keyChars) { add(`${name}.untracked`); return false; }
    table.set(key, detail || true); entries++; chars += key.length;
    tableChars.set(name, heldChars + key.length);
    add(`${name}.distinctTracked`);
    return false;
  }
  // Exact canonical serialization, not a probabilistic hash. Only finite plain data.
  // No graph references or canonical-string memo are retained by object identity.
  function structural(value) {
    let nodes = 0, bytes = 0;
    const active = new WeakSet();
    function walk(x, depth) {
      if (++nodes > limits.structuralNodes || depth > limits.structuralDepth) throw 'bound';
      let out;
      if (x === null || typeof x !== 'object') {
        if (typeof x === 'function' || typeof x === 'symbol' || typeof x === 'undefined') throw 'unsupported';
        out = id(x);
      } else {
        if (active.has(x)) throw 'cycle';
        const proto = Object.getPrototypeOf(x);
        if (proto !== Object.prototype && proto !== null) throw 'prototype';
        active.add(x);
        const keys = Reflect.ownKeys(x);
        if (keys.some(k => typeof k !== 'string')) throw 'symbol';
        keys.sort();
        const parts = [];
        for (const key of keys) {
          const d = Object.getOwnPropertyDescriptor(x, key);
          if (!d || !('value' in d)) throw 'accessor';
          parts.push([key, walk(d.value, depth + 1)]);
        }
        active.delete(x);
        out = JSON.stringify(parts);
      }
      bytes += out.length;
      if (bytes > limits.structuralChars) throw 'bound';
      return out;
    }
    try { const text = walk(value, 0); structuralNodes += nodes; return text; }
    catch (reason) { structuralNodes += nodes; add(`structural.skipped.${reason}`); return null; }
  }
  function contextKey(context) {
    if (!context || context.$ !== 'emitter_steps_v1.cps_provider_7_NfContext') throw Error('E06 unexpected NfContext representation');
    // Maps are immutable: their exact root pair is a semantic version. Context
    // wrappers can be reconstructed by nf_named without changing that version.
    return tuple([id(context.families), id(context.type_functions)]);
  }
  function nf(name, context, descriptor, env, level, fuel, isPublic) {
    const version = contextKey(context), ek = envId(env);
    const dims = [epoch, version, id(descriptor), ek, id(level), id(fuel)];
    seen(`${name}.exactIdentity`, tuple(dims));
    seen(`${name}.wrapperIdentity`, tuple([epoch, id(context), ...dims.slice(2)]));
    add(`${name}.env.${ek === 'Nil' ? 'empty' : 'nonempty'}`);
    add(`${name}.fuel.${String(fuel) === '0' ? 'zero' : 'positive'}`);
    if (!isPublic) return;
    if (structuralAttempts >= limits.structuralRequests) { add('structural.skipped.requestLimit'); return; }
    structuralAttempts++;
    const d = structural(descriptor), e = structural(env);
    if (d === null || e === null) return;
    add('structural.completeRequests');
    seen(`${name}.exactStructure`, tuple([epoch, version, d, e, id(level), id(fuel)]));
  }
  function entry(name, a, b, c, d, e, f) {
    serial++;
    const phase = globalThis.__allExperimentPhase || 'startup';
    add(`calls.${phase}.${name}`);
    if (name === 'program_source') {
      epoch++;
      if (events.length < 128) events.push({ name, phase, serial, epoch });
    } else if (['js_scalar_program', 'codes', 'declarations', 'families', 'type_functions'].includes(name) && events.length < 128) {
      // A first-entry landmark only, not a CPS completion time.
      if (!events.some(x => x.name === name && x.epoch === epoch)) events.push({ name, phase, serial, epoch });
    }
    if (name === 'nf' || name === 'nf_descriptor') nf(name, a, b, c, d, e, false);
    if (name === 'normalize') nf(name, a, b, c, 0, d, true);
    if (name === 'normalize_in' || name === 'answer_in') nf(name, a, b, { $: 'Nil' }, 0, 1024, false);
    if (name === 'nf_context') seen('nfContext.inputLists', tuple([id(a), id(b)]));
    if (name === 'family_index' || name === 'function_index') {
      seen(`${name}.inputSuffix`, tuple([id(a)]));
      add(`${name}.${a?.$ === 'Con' ? 'cons' : a?.$ === 'Nil' ? 'nil' : 'unexpected'}`);
    }
    if (name === 'normalize_result') {
      if (a?.$ === 'emitter_steps_v1.cps_provider_7_NfFail') {
        add(a.message === 'the type expression did not normalize within its reduction budget' ? 'normalize.result.budgetFailure' : 'normalize.result.otherFailure');
      } else if (a?.$ === 'emitter_steps_v1.cps_provider_7_NfOk') add('normalize.result.ok');
      else throw Error('E06 unexpected normalize result');
    }
    if (name === 'js_native_markers') seen('nativeMarkers.sameProgram', tuple([id(a)]));
    if (name === 'js_scalar_block_ok' || name === 'js_scalar_block') {
      seen(`${name}.exactInputs`, tuple([epoch, id(a), id(b), id(c)]));
      seen(`${name}.sameBodyAnyRecord`, tuple([epoch, id(a)]));
    }
    if (name === 'plan_of' || name === 'plan_block') {
      if (a && typeof a === 'object') {
        postBlocks.set(a, epoch);
        if (a.$ === '../bend2/selfhost/backend_ir.Let' && a.op && typeof a.op === 'object') postOps.set(a.op, epoch);
      }
      seen(`${name}.samePostScalarBody`, tuple([epoch, id(a)]));
      // plan_block threads an accumulator; body-only repeat is work, NOT a memo key.
      if (name === 'plan_block') seen('plan_block.exactInputs', tuple([epoch, id(a), id(b)]));
    }
    if (name === 'block' || name === 'conts') {
      const post = a && postBlocks.get(a) === epoch;
      add(`${name}.${post ? 'seenByPostScalarPlan' : 'notSeenByPlan'}`);
      seen(`${name}.sameBody`, tuple([epoch, id(a)]));
      seen(`${name}.exactInputs`, tuple([epoch, id(a), id(b)]));
    }
    if (name === 'op_reads') {
      const post = a && postOps.get(a) === epoch;
      const empty = b?.locals?.$ === 'Nil' && b?.slots?.$ === 'Nil';
      const stage = post ? 'postScalar' : 'preOrUnclassified';
      seen(`op_reads.${stage}.sameOp`, tuple([epoch, id(a)]));
      seen(`op_reads.${stage}.exactInputs`, tuple([epoch, id(a), empty ? 'emptyReads' : id(b)]));
    }
    if (['suffix_op', 'suffix_atom', 'suffix_args', 'suffix_join', 'suffix_caps'].includes(name)) {
      seen(`${name}.exactInputs`, tuple([epoch, id(a), id(b)]));
    }
    if (name === 'suffix_fold' || name === 'suffix_prefix' || name === 'caps_bound') {
      add(`${name}.${a?.$ === 'Con' ? 'cons' : a?.$ === 'Nil' ? 'nil' : 'unexpected'}`);
      seen(`${name}.sameListSuffix`, tuple([epoch, id(a)]));
      const args = name === 'suffix_fold' ? [a, b] : name === 'suffix_prefix' ? [a, b, c] : [a, b, c, d];
      seen(`${name}.exactInputs`, tuple([epoch, ...args.map(id)]));
    }
  }
  function site(label, families, functions) {
    const pair = tuple([id(families), id(functions)]);
    seen('nfContext.callsiteInputs', pair, label);
    seen(`nfContext.site.${label}`, pair);
  }
  function result() {
    return { schema: 1, counters: { ...counts }, retainedScalarKeys: entries, retainedKeyChars: chars, assignedWeakIdentities: nextId,
      structuralAttempts, structuralNodes, limits, events: events.slice(), indexExamples: indexExamples.slice(),
      coverage: { targetOperationsSuppressed: 0, resultMemoization: false, timings: false, structuralCoverage: 'bounded first public normalize requests; skipped counts explicit', identityVersion: 'immutable NF map-root pair; BIR object identity plus program_source epoch', validationRedundancyClaim: false } };
  }
  return { entry, site, result };
}

export function instrument(source, context) {
  if (state || globalThis[HOOK]) throw Error('E06/E10 plugin installed twice');
  const original = readFileSync(resolve(context.repository, IMAGE), 'utf8');
  if (hash(original) !== SHA) throw Error('E06/E10 immutable R12 image hash mismatch');
  const lines = source.split('\n');
  const declarations = new Map(), functions = new Map(), functionNames = new Map();
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const fn = /^function (\$[bk]\d+)\(([^)]*)\)\{/.exec(line);
    if (fn) {
      if (functions.has(fn[1])) throw Error(`duplicate generated function ${fn[1]}`);
      functions.set(fn[1], { line: i, prefix: fn[0], args: fn[2].split(',').filter(x => x !== '$td=0') });
    }
    const binding = /^\$D\["([^"]+)"\]=/.exec(line);
    if (!binding) continue;
    const calls = [...line.matchAll(/\?((?:\$b)\d+)\(/g)].map(m => m[1]);
    if (calls.length === 1) {
      if (declarations.has(binding[1])) throw Error(`duplicate declaration ${binding[1]}`);
      declarations.set(binding[1], calls[0]);
      functionNames.set(calls[0], binding[1]);
    }
  }
  const mapping = [];
  function hook(provider, name, arity, metric = name) {
    const binding = `emitter_steps_v1.emitter_body_cps_provider_${provider}_${name}`;
    const id = declarations.get(binding), fn = functions.get(id);
    if (!fn || fn.args.length !== arity || fn.args.some((a, i) => a !== `$v${i}`)) throw Error(`E06/E10 missing or changed ${binding}`);
    lines[fn.line] = lines[fn.line].replace(fn.prefix, `${fn.prefix}globalThis.${HOOK}.entry(${JSON.stringify(metric)}${fn.args.length ? ',' : ''}${fn.args.join(',')});`);
    mapping.push({ binding, function: id, arity, metric, imageLine: fn.line + 1 });
    return id;
  }
  for (const [name, n] of [['nf_context',2],['family_index',1],['function_index',1],['nf',5],['nf_descriptor',5],['nf_descriptor_step',5],['nf_reduce',5],['normalize',4],['normalize_in',2],['answer_in',2]]) hook(7, name, n);
  for (const [name, n] of [['js_scalar_program',1],['js_scalar',1],['js_scalar_block_ok',3],['js_scalar_block',3],['js_scalar_op_ok',3],['js_scalar_field_at',2],['plan_of',1],['plan_block',2],['op_reads',2],['atom_reads',2],['args_reads',2],['fields_reads',2],['suffix_op',2],['suffix_atom',2],['suffix_args',2],['suffix_join',2],['suffix_caps',2],['suffix_fold',2],['suffix_prefix',3],['caps_bound',4],['block',2],['conts',2],['code',1],['codes',1],['declarations',3],['families',1],['type_functions',1],['constructor_layouts',1],['program_source',2],['js_native_markers',1]]) hook(8, name, n);
  // The normalization match is discovered by its exact body shape, not its
  // generated match number. It is the CPS result of normalize's nf call.
  const outcome = [];
  for (const [id, fn] of functions) {
    const text = lines[fn.line];
    if (fn.args.length === 1 && text.includes('$v0.$==="emitter_steps_v1.cps_provider_7_NfFail"') && text.includes('$v0.$==="emitter_steps_v1.cps_provider_7_NfOk"') && text.includes('"../bend2/selfhost/backend_ir.DescriptorFailure"')) outcome.push([id, fn]);
  }
  if (outcome.length !== 1) throw Error(`E06 normalize result match count ${outcome.length}`);
  const [outcomeId, outcomeFn] = outcome[0];
  lines[outcomeFn.line] = lines[outcomeFn.line].replace(outcomeFn.prefix, `${outcomeFn.prefix}globalThis.${HOOK}.entry("normalize_result",${outcomeFn.args[0]});`);
  mapping.push({ binding: functionNames.get(outcomeId), function: outcomeId, arity: 1, metric: 'normalize_result', imageLine: outcomeFn.line + 1 });

  // Observe both the direct and trampoline call arms. Every expression still
  // evaluates the original call exactly once, with its original arguments.
  const nfId = declarations.get('emitter_steps_v1.emitter_body_cps_provider_7_nf_context');
  const callsites = [];
  const direct = new RegExp(`${escape(nfId)}\\((\\$[cv]\\d+),(\\$[cv]\\d+),(\\$td(?:\\+1)?)\\)`, 'g');
  const trampoline = new RegExp(`run_named2\\(${escape(nfId)},(\\$[cv]\\d+),(\\$[cv]\\d+),(\\$td)\\)`, 'g');
  for (const [id, fn] of functions) {
    if (id === nfId) continue;
    let hits = 0;
    const label = functionNames.get(id) || id;
    function inject(full, a, b) { hits++; return `(globalThis.${HOOK}.site(${JSON.stringify(label)},${a},${b}),${full})`; }
    lines[fn.line] = lines[fn.line].replace(direct, inject).replace(trampoline, inject);
    if (hits) callsites.push({ function: id, binding: functionNames.get(id) || null, imageLine: fn.line + 1, arms: hits });
  }
  if (!callsites.length) throw Error('E06 no NF context callsites mapped');
  state = observer();
  globalThis[HOOK] = state;
  return { source: lines.join('\n'), metadata: { plugin: 'E06-E10-normalization-assembly', immutableImage: IMAGE, immutableSha256: SHA, inputCopySha256: hash(source), mapping, nfContextCallsites: callsites, observationsOnly: true, noContinuationWrapping: true } };
}

export function snapshot() {
  return state ? state.result() : { schema: 1, installed: false };
}
