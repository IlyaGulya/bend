import {createHash} from 'node:crypto';
import {readFileSync, realpathSync} from 'node:fs';
import {dirname, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const HOOK = '__bendN050608ScalarCensus';
const IMAGE_SHA = '85aff9e534c18b4a1d6acac5f3237571dabc58f2c1a75a7ea2040f1c477ab60e';
const BIR = '../bend2/selfhost/backend_ir.';
const ARENA = '../bend2/selfhost/checker_arena.';
const LOWER = 'emitter_steps_v1.cps_provider_1_';
const sha = x => createHash('sha256').update(x).digest('hex');
const assert = (ok, message) => { if (!ok) throw Error('N05/N06/N08: ' + message); };
let observer, frozenWorkload = false;

// All retained runtime data are numeric scalars or fixed-width histograms.
// No WeakMap, owner object, list, arena, descriptor, callback or event is retained.
function makeObserver() {
  const counters = Object.create(null), histograms = Object.create(null);
  for (const name of ['lookupWidth','hitWidth','missWidth','searchDepth','hitDepth','missDepth','hitAge','frameFinalWidth','applyPrefix','sugarAppendPrefix','stringChars']) histograms[name] = Array(34).fill(0);
  let searching = false, width = 0, depth = 0, owner = 0, identity = 0;
  let appendMode = 0, appendCells = 0, stringActive = false, stringChars = 0;
  const add = (key, n = 1) => {
    const value = (counters[key] || 0) + n;
    assert(Number.isSafeInteger(value), 'counter overflow ' + key);
    counters[key] = value;
  };
  const u32 = value => { assert(Number.isInteger(value) && value >= 0 && value <= 0xffffffff, 'unexpected U32'); return value; };
  const hist = (name, n) => {
    assert(Number.isSafeInteger(n) && n >= 0, 'invalid histogram sample');
    const bucket = n === 0 ? 0 : Math.min(33, Math.floor(Math.log2(n)) + 1);
    histograms[name][bucket]++;
  };
  const digest = (key, a, b) => { counters[key] = (Math.imul((counters[key] || 2166136261) ^ a, 16777619) ^ b) >>> 0; };
  const startAppend = mode => { assert(appendMode === 0, 'overlapping observed append'); appendMode = mode; appendCells = 0; };
  return {
    resolveOwner(same) { add(same === true ? 'owner.local' : 'owner.external'); },
    begin(state, slot, from, id) {
      assert(!searching, 'overlapping capture searches');
      assert(state?.$ === LOWER + 'State' && state.frame?.$ === LOWER + 'Frame', 'capture frame representation');
      assert(slot?.$ === LOWER + 'Slot' && slot.owner === from && slot.identity === id, 'capture request slot mismatch');
      width = u32(state.frame.capture_count); owner = u32(from); identity = u32(id); depth = 0; searching = true;
      add('lookup.requests'); hist('lookupWidth', width); digest('lookup.compositeKeyDigest32', owner, identity);
      if (width > (counters['lookup.maxWidth'] || 0)) counters['lookup.maxWidth'] = width;
    },
    capture(captures, from, id) {
      assert(searching && owner === from && identity === id, 'capture chain context mismatch');
      add('lookup.captureFoundEntries');
      if (captures?.$ === 'Nil') { add('lookup.nilVisits'); return; }
      assert(captures?.$ === 'Con', 'capture list representation');
      depth++; add('lookup.cellsVisited');
      const slot = captures.head?.slot;
      if (captures.head?.$ !== LOWER + 'Capture' || slot?.$ !== LOWER + 'Slot') { add('lookup.skippedNonSlotCells'); return; }
      add('lookup.comparisons'); add('lookup.scalarEqualities', 2);
      if (slot.owner === from) add('lookup.ownerEqualComparisons');
      if (slot.identity === id) add('lookup.identityEqualComparisons');
      if (slot.identity === id && slot.owner !== from) add('lookup.identityCollisionDifferentOwner');
      if (slot.owner === from && slot.identity === id) add('lookup.compositeMatches');
    },
    next(found) { assert(searching, 'capture next without search'); add(found === true ? 'lookup.nextTrue' : 'lookup.nextFalse'); },
    resolved(found, count, slot) {
      assert(searching && count === width && slot?.owner === owner && slot?.identity === identity, 'capture result mismatch');
      hist('searchDepth', depth); add('lookup.searchDepthSum', depth);
      if (depth > (counters['lookup.maxDepth'] || 0)) counters['lookup.maxDepth'] = depth;
      if (found?.$ === 'Some') {
        const index = u32(found.value), age = width - 1 - index;
        assert(age >= 0 && depth === age + 1, 'capture first-use ordering changed');
        add('lookup.hits'); hist('hitDepth', depth); hist('hitWidth', width); hist('hitAge', age);
        add(age === 0 ? 'lookup.hitNewest' : 'lookup.hitOlder');
        if (age >= 4) add('lookup.hitAgeAtLeast4');
        if (width >= 4 && age * 2 >= width) add('lookup.hitOlderHalfWide');
        add('lookup.hitTraversalBeyondFirst', Math.max(0, depth - 1));
      } else {
        assert(found?.$ === 'None' && depth === width, 'capture miss did not traverse full frame');
        add('lookup.misses'); hist('missDepth', depth); hist('missWidth', width);
        // A miss inserts exactly one previously absent (owner,identity) in this frame.
        // This is an exact sum of frame-local distinct entries, NOT global cardinality.
        add('lookup.frameLocalDistinctInsertions'); digest('lookup.insertedCompositeKeyDigest32', owner, identity);
      }
      searching = false; width = depth = owner = identity = 0;
    },
    enter() { add('frame.enters'); },
    leave(state) {
      assert(state?.frame?.$ === LOWER + 'Frame', 'leave frame representation');
      add('frame.leaves'); hist('frameFinalWidth', u32(state.frame.capture_count));
      add('frame.finalCaptureSlots', state.frame.capture_count);
    },
    apply(fn) {
      add('descriptorApply.calls');
      if (fn?.$ === BIR + 'DescriptorRef') { add('descriptorApply.ref'); startAppend(1); }
      else add('descriptorApply.nonRef');
    },
    sugarAppend(result) {
      assert(result?.$ === 'emitter_steps_v1.cps_provider_10_CatalogResult', 'sugar append input');
      add('descriptorSugar.adtAppendCalls'); startAppend(2);
    },
    append(prefix) {
      if (appendMode === 0) return;
      if (prefix?.$ === 'Con') { appendCells++; add(appendMode === 1 ? 'descriptorApply.traversedAppendCells' : 'descriptorSugar.traversedAppendCells'); return; }
      assert(prefix?.$ === 'Nil', 'append list representation');
      const label = appendMode === 1 ? 'descriptorApply' : 'descriptorSugar';
      hist(appendMode === 1 ? 'applyPrefix' : 'sugarAppendPrefix', appendCells);
      add(label + '.completedAppends'); add(label + '.prefixLengthSum', appendCells);
      if (appendCells > (counters[label + '.maxPrefix'] || 0)) counters[label + '.maxPrefix'] = appendCells;
      if (appendCells >= 4) add(label + '.prefixAtLeast4');
      appendMode = appendCells = 0;
    },
    sugar(node) {
      add('descriptorSugar.nodeCalls');
      if (node?.$ === ARENA + 'TermApp') add('descriptorSugar.termApp');
      else if (node?.$ === ARENA + 'TermRef') add('descriptorSugar.termRef');
      else if (node?.$ === ARENA + 'TermAdt') add('descriptorSugar.termAdt');
      else add('descriptorSugar.other');
    },
    node(node) {
      add('descriptorNode.calls');
      if (node?.$ === ARENA + 'TermApp') add('descriptorNode.termApp');
      if (node?.$ !== ARENA + 'TermString') return;
      assert(!stringActive, 'overlapping descriptor strings');
      stringActive = true; stringChars = 0; add('descriptorString.termStringRoutes');
    },
    string(chars) {
      assert(stringActive, 'string_descriptor outside observed TermString route');
      add('descriptorString.entries');
      if (chars?.$ === 'Con') {
        stringChars++; add('descriptorString.chars');
        if (chars.head === 0) add('descriptorString.nulChars');
        if (chars.head > 0xffff) add('descriptorString.astralChars');
      } else {
        assert(chars?.$ === 'Nil', 'descriptor character list representation');
        hist('stringChars', stringChars); add('descriptorString.completedStrings');
        if (stringChars === 0) add('descriptorString.emptyStrings');
        stringActive = false; stringChars = 0;
      }
    },
    word(count) {
      add('descriptorString.wordEntries');
      if (count === 32 || count === 32n) add('descriptorString.word32Starts');
      if (count === 0 || count === 0n) add('descriptorString.wordNilVisits');
      else add('descriptorString.wordBitSteps');
    },
    bit() { add('descriptorString.bitCalls'); },
    constructed(group) { add('descriptorString.constructedDescriptors'); add('descriptorString.constructed.' + group); },
    check() {
      assert(!searching && !appendMode && !stringActive, 'unfinished scalar observation');
      const n = key => counters[key] || 0;
      assert(n('lookup.requests') === n('lookup.hits') + n('lookup.misses'), 'capture request conservation');
      assert(n('descriptorApply.ref') === n('descriptorApply.completedAppends'), 'append completion conservation');
      assert(n('descriptorString.termStringRoutes') === n('descriptorString.completedStrings'), 'string route conservation');
      assert(n('descriptorString.word32Starts') === n('descriptorString.chars'), '32-bit words per character');
      assert(n('descriptorString.wordBitSteps') === 32 * n('descriptorString.chars'), 'word bit-work conservation');
      assert(n('descriptorString.constructedDescriptors') === 68 * n('descriptorString.chars') + n('descriptorString.completedStrings'), 'constructed descriptor conservation');
    },
    result() {
      return {schemaVersion:1, counters:{...counters}, histograms:Object.fromEntries(Object.entries(histograms).map(([k,v]) => [k,[...v]])),
        histogramBuckets:'0; [1,1]; [2,3]; [4,7]; ...; [2^31,2^32-1]; >=2^32',
        inFlight:{captureSearch:searching, appendMode, stringActive},
        retention:'fixed scalar counters and 11 x 34 histogram cells; no source/owner/list references',
        nativeLane:'NOT_OBSERVED', diagnosticOnly:true, compilerAccepted:false};
    }
  };
}

export function instrument(source, context) {
  frozenWorkload = context.target === undefined;
  assert(!observer && !globalThis[HOOK], 'plugin already installed');
  const config = JSON.parse(readFileSync(resolve(HERE, 'config.json'), 'utf8'));
  const request = JSON.parse(readFileSync(config.request, 'utf8'));
  for (const [path, expected] of Object.entries({...request.pins, ...request.inputs, ...config.pins})) {
    assert(realpathSync(path) === path && sha(readFileSync(path)) === expected, 'pin drift: ' + path);
  }
  assert(realpathSync(context.image) === request.image, 'not original genuine R12 image');
  assert(sha(source) === IMAGE_SHA, 'input must be unmodified genuine R12, install this plugin first');
  const lines = source.split('\n'), functions = new Map(), declarations = new Map(), named = new Set();
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i], fn = /^function (\$[bk]\d+)\(([^)]*)\)\{/.exec(line);
    if (fn) { assert(!functions.has(fn[1]), 'duplicate function'); functions.set(fn[1], {id:fn[1], line:i, prefix:fn[0], args:fn[2].split(',').filter(x => x !== '$td=0'), body:line}); }
    const d = /^\$D\["([^"]+)"\]=/.exec(line);
    if (!d) continue;
    const calls = [...line.matchAll(/\?(\$b\d+)\(/g)];
    if (calls.length === 1) { assert(!declarations.has(d[1]), 'duplicate declaration'); declarations.set(d[1], {id:calls[0][1], line:i, body:line}); named.add(calls[0][1]); }
  }
  const mapping = [], constructionSites = [];
  function select(binding, arity) {
    const d = declarations.get(binding), fn = functions.get(d?.id);
    assert(fn && fn.args.length === arity, 'missing/changed declaration ' + binding);
    return {d, fn};
  }
  function hook(binding, arity, method, positions) {
    const {d,fn} = select(binding,arity);
    const expression = `globalThis.${HOOK}.${method}(${positions.map(i => fn.args[i]).join(',')});`;
    lines[fn.line] = lines[fn.line].replace(fn.prefix, fn.prefix + expression);
    mapping.push({binding,function:fn.id,imageLine:fn.line+1,declarationLine:d.line+1,arity,arguments:fn.args,
      declarationSha256:sha(d.body),bodySha256:sha(fn.body),declaration:d.body,body:fn.body,injected:expression});
    return fn.id;
  }
  const lower = name => 'emitter_steps_v1.emitter_body_cps_provider_1_' + name;
  const catalog = name => 'emitter_steps_v1.emitter_body_cps_provider_10_' + name;
  hook(lower('resolve_owner'),3,'resolveOwner',[0]);
  hook(lower('native_match_resolve_owner_0'),4,'begin',[0,1,2,3]);
  hook(lower('capture_found'),3,'capture',[0,1,2]);
  hook(lower('capture_found_next'),5,'next',[0]);
  hook(lower('resolve_capture'),13,'resolved',[0,7,10]);
  hook(lower('enter'),1,'enter',[]);
  hook(lower('leave'),4,'leave',[0]);
  hook(catalog('descriptor_apply'),2,'apply',[0]);
  hook(catalog('native_match_descriptor_sugar_2'),4,'sugarAppend',[0]);
  hook('List.append',2,'append',[0]);
  hook(catalog('native_match_descriptor_sugar_5'),5,'sugar',[0]);
  hook(catalog('descriptor_node'),3,'node',[1]);
  const roots = [
    [hook(catalog('string_descriptor'),2,'string',[0]),'string'],
    [hook(catalog('string_word'),3,'word',[0]),'word'],
    [hook(catalog('string_bit'),2,'bit',[]),'bit']
  ];
  // Follow only compiler-private split/resume helpers. Stop at EVERY other
  // declaration boundary, including the other string roots. This selects actual
  // construction statements, not estimates from entry count or all String data.
  const marked = new Set();
  for (const [root,group] of roots) {
    const pending = [root], visited = new Set();
    while (pending.length) {
      const id = pending.pop();
      if (visited.has(id) || (id !== root && named.has(id))) continue;
      visited.add(id);
      const fn = functions.get(id); assert(fn, 'missing private helper ' + id);
      for (const m of fn.body.matchAll(/\$[bk]\d+\b/g)) if (functions.has(m[0]) && !visited.has(m[0])) pending.push(m[0]);
      const pattern = /const (\$v\d+)=\(\{\$:"\.\.\/bend2\/selfhost\/backend_ir\.DescriptorConstructor",/g;
      const hits = [...fn.body.matchAll(pattern)];
      if (!hits.length) continue;
      assert(!marked.has(id), 'shared string construction helper'); marked.add(id);
      lines[fn.line] = lines[fn.line].replace(pattern, text => `globalThis.${HOOK}.constructed(${JSON.stringify(group)});${text}`);
      constructionSites.push({group,function:id,imageLine:fn.line+1,sites:hits.length,bodySha256:sha(fn.body),body:fn.body});
    }
  }
  assert(constructionSites.reduce((n,s) => n+s.sites,0) === 8, 'string constructor site inventory changed');
  // Explicitly inventory bridge bodies even where no extra observation is needed.
  const bridges = ['native_match_descriptor_node_11','native_match_descriptor_node_12','descriptor_sugar'].map(name => {
    const binding = catalog(name), d = declarations.get(binding), fn = functions.get(d?.id);
    assert(fn, 'missing bridge ' + binding);
    return {binding,function:fn.id,imageLine:fn.line+1,bodySha256:sha(fn.body),declarationSha256:sha(d.body),body:fn.body,declaration:d.body};
  });
  observer = makeObserver(); globalThis[HOOK] = observer;
  const transformed = lines.join('\n');
  return {source:transformed, metadata:{schemaVersion:1,plugin:'N05-N06-N08-passive-scalar',image:{path:request.image,sha256:IMAGE_SHA},
    request:{path:config.request,sha256:sha(readFileSync(config.request))},inputPins:request.inputs,sourcePins:config.pins,
    inputSha256:sha(source),outputSha256:sha(transformed),mapping,constructionSites,bridges,
    authority:'genuine R12 stage1 JS only; native lane not inferred', noContinuationWrapping:true,noOwnerRetention:true,
    expectedOutput:request.expectedSelfhostOutput,expectedSteps:config.expectedSteps}};
}
export function snapshot() { return observer ? observer.result() : {installed:false}; }
export function onPhase(name) { if (name === 'emit' || name === 'emit-js' || name === 'emit-c') observer?.check(); }
export function onFinish(kind, _value, steps) {
  const expected = {Template:1004927,Checker:10078835,Emitter:1225480};
  if (frozenWorkload) assert(Object.hasOwn(expected,kind) && steps === expected[kind], 'original frozen step count changed: ' + kind + '=' + steps);
  if (kind === 'Emitter') observer.check();
}
