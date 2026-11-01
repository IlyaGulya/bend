import {traceTableFor,typedTraceEvents} from './compiler_stage_profile.mjs';
import {types} from 'node:util';

// Diagnostic only: no native callbacks, evaluation, pruning, or compiler mutation.
// The schema is backend_ir.bend, not a walk over arbitrary JavaScript properties.
// Native JS Nat/Bool/String representations are scalar; lists and Maybe are ADTs.
const own = (value, key) => {
  if (value === null || typeof value !== 'object' || types.isProxy(value) || Array.isArray(value)) return undefined;
  const field = Object.getOwnPropertyDescriptor(value, key);
  return field && Object.hasOwn(field, 'value') ? field.value : undefined;
};
const tag = value => own(value, '$');
const simple = value => typeof value === 'string' ? value.slice(value.lastIndexOf('.') + 1) : null;
const object = value => value !== null && typeof value === 'object' && !types.isProxy(value) && !Array.isArray(value);
const u32 = value => Number.isInteger(value) && value >= 0 && value <= 0xffffffff;
const nat = value => typeof value === 'bigint' ? value >= 0n : Number.isSafeInteger(value) && value >= 0;
const bounded = (value, fallback, ceiling) => Number.isSafeInteger(value) && value > 0 ? Math.min(value, ceiling) : fallback;
const SHA256 = /^[a-f0-9]{64}$/;
const RUNTIME_CTORS = ['Nil', 'Con', 'Tuple', 'SNil', 'SCon', 'WCon', 'Emit', 'Halt', 'Exit', 'Fail', 'Done', 'Ready', 'Wait', 'None', 'Some'];
const PRIMITIVES = new Set(('U32Add U32Sub U32Mul U32Div NatAdd NatSub NatMul NatCmp NatMin NatMax StringAppend BoolOr BoolXor U32IsZero F32Asin F32Acos F32Atan F32Sinh F32Cosh F32Tanh U32Mod U32And U32Or U32Xor U32IsEq U32IsNe U32IsLt U32IsLe U32IsGt U32IsGe U32Inc U32Not U32Shl U32Shr U32Shln U32Shrn U32Cmp U32ToNat U32FromNat F32Add F32Sub F32Mul F32Div F32Mod F32Neg F32Sqrt F32Abs F32ToU32 F32Bits F32Show F32Read F32IsEq F32IsNe F32IsLt F32IsLe F32IsGt F32IsGe F32Pow F32Atan2 F32Exp F32Log F32Log2 F32Log10 F32Sin F32Cos F32Tan F32Floor F32Ceil F32Trunc F32ToNat U32ToF32 NatDouble NatIsLt NatDivmod StringEq MapBit MapFind StringCmp StringToList StringLength ArrayNew ArraySet ArrayGet ArraySwap ArraySize ArrayClone ArrayAtomicAdd ArrayAtomicMin ArrayAtomicMax ArrayAtomicAnd ArrayAtomicOr ArrayAtomicXor ArrayAtomicExch ArrayAtomicCas ArrayAtomicFadd NatPredecessor NatSuccessor CharNew CharCode StringHead StringTail WordToU32 U32ToWord F32FromBits F32FromWord F32ToWord ArrayLeaf ArrayNode ArrayLeafValue ArrayLeft ArrayRight IsArrayLeaf IsArrayNode IsNatZero IsNatSuccessor IsStringEmpty IsStringNonempty IsTrue IsFalse SameValue FloatBitsEqual').split(' ').map(name => 'Prim' + name));
const SCHEMA = {
  Program: {Program: 'codes:[Code] declarations:[Declaration] constructors:[ConstructorLayout] families:[Family] type_functions:[TypeFunction] ending:Ending'},
  Use: {Affine: '', Many: ''}, Quantity: {Erased: '', Once: '', Unrestricted: ''},
  Atom: {Local: 'id:u32', Capture: 'slot:u32', Symbol: 'id:u32 key:string', Word: 'value:u32', Natural: 'value:nat', FloatBits: 'bits:u32', TextValue: 'value:string', Boolean: 'value:bool', Null: '', Undefined: ''},
  Arg: {Arg: 'use:Use value:Atom'}, Parameter: {Parameter: 'id:u32 use:Use'},
  Field: {Field: 'identity:u32 key:string use:Use value:Atom'},
  Op: {Copy: 'value:Atom', PrimitiveCall: 'primitive:Primitive args:[Arg] types:[Descriptor]', Closure: 'code:u32 captures:[Arg] parameters:[Parameter]', Direct: 'code:u32 args:[Arg]', Apply: 'fn:Atom arg:Arg', LoadSymbol: 'id:u32 key:string', Construct: 'constructor:u32 tag:string fields:[Field]', Project: 'value:Atom constructor:u32 field:u32 key:string', HasTag: 'value:Atom constructor:u32 tag:string'},
  Block: {Return: 'value:Atom', Let: 'id:u32 op:Op next:Block', Branch: 'condition:Atom yes:Block no:Block', Region: 'label:u32 body:Block next:Block', LeaveRegion: 'label:u32', TailDirect: 'code:u32 args:[Arg]', TailApply: 'fn:Atom arg:Arg', Failure: 'message:string'},
  Code: {Code: 'id:u32 captures:[Use] parameters:[Parameter] body:Block'},
  Declaration: {FunctionDeclaration: 'key:string code:u32 parameters:[Parameter]', LazyDeclaration: 'key:string body:Block', NativeDeclaration: 'key:string primitive:Primitive quantities:[Quantity]', ForeignDeclaration: 'key:string namespace:string imported:string arity:nat sources:[string] quantities:[Quantity] span:opaque parameter_types:[Descriptor] result:Descriptor'},
  ConstructorLayout: {ConstructorLayout: 'id:u32 key:string native:?string fields:[?string]'},
  DescriptorPattern: {DescriptorBinder: 'quantity:Quantity', DescriptorConstructorPattern: 'key:string fields:[DescriptorPattern]'},
  Descriptor: {DescriptorNull: '', DescriptorRef: 'key:string args:[Descriptor]', DescriptorParameter: 'index:nat', DescriptorQuantityKind: '', DescriptorQuantity: 'quantity:Quantity', DescriptorKind: 'quantity:Descriptor', DescriptorMinimum: 'left:Descriptor right:Descriptor', DescriptorArrow: 'quantity:Quantity domain:Descriptor body:Descriptor', DescriptorLambda: 'quantity:?Quantity body:Descriptor', DescriptorConstructor: 'key:string args:[Descriptor]', DescriptorApplication: 'fn:Descriptor arg:Descriptor', DescriptorSubstitution: 'index:nat value:Descriptor body:Descriptor', DescriptorLet: 'values:[Descriptor] body:Descriptor', DescriptorLocal: 'patterns:[DescriptorPattern] values:[Descriptor] body:Descriptor', DescriptorMatch: 'values:[Descriptor] cases:[Descriptor]', DescriptorCase: 'patterns:[DescriptorPattern] body:Descriptor', DescriptorBind: 'value:Descriptor body:Descriptor', DescriptorEquality: 'left:Descriptor right:Descriptor ty:Descriptor', DescriptorReflexivity: '', DescriptorFailure: 'message:string', DescriptorFill: 'head:Descriptor args:[Descriptor]', DescriptorPlus: 'head:Descriptor args:[Descriptor]', DescriptorNamedFill: 'key:string head:Descriptor args:[Descriptor]', DescriptorNamedPlus: 'key:string head:Descriptor args:[Descriptor]'},
  DescriptorField: {DescriptorField: 'key:?string quantity:Quantity ty:Descriptor'},
  DescriptorArm: {DescriptorArm: 'key:string fields:[DescriptorField]'},
  Family: {Family: 'key:string name:string native:?string quantity_prefix:nat arity:nat arms:[DescriptorArm]'},
  TypeFunction: {TypeFunction: 'key:string native:?string quantity_prefix:nat arity:nat body:Descriptor'},
  Entry: {Entry: 'code:u32 arity:nat'}, Export: {Export: 'key:string entry:?Entry parameter_types:[Descriptor] result:Descriptor'},
  Ending: {Executable: 'main_type:Descriptor', Library: 'exports:[Export]'},
};
for (const variants of Object.values(SCHEMA)) for (const [name, fields] of Object.entries(variants)) {
  variants[name] = fields ? fields.split(' ').map(field => field.split(':')) : [];
}

function limits(options) {
  return {nodes: bounded(options.maxNodes, 2000000, 8000000), rows: bounded(options.maxRows, 250000, 1000000), examples: bounded(options.maxExamples, 24, 256), edges: bounded(options.maxEdges, 1000000, 4000000)};
}
function summary(values, limit) {
  const examples = [];
  let count = 0;
  for (const value of values) { if (count < limit) examples.push(value); count += 1; }
  return {count, examples, examplesTruncated: count > examples.length};
}
function provenance(options) {
  return {producerIdentity: typeof options.producerIdentity === 'string' ? options.producerIdentity : null,
    inputSha256: typeof options.inputSha256 === 'string' && SHA256.test(options.inputSha256) ? options.inputSha256 : null,
    binding: 'caller-supplied identity and primary-input digest; not independently rehashed by the observer'};
}

// Validate before interpreting. Iterative enter/leave frames detect actual cycles
// while permitting shared immutable subtrees; the work bound includes list cells.
function validate(program, budget, expectedTag) {
  const rootTag = tag(program);
  if (typeof rootTag !== 'string' || simple(rootTag) !== 'Program' || (expectedTag !== undefined && rootTag !== expectedTag))
    return {status: 'invalid', reason: 'expected the declared BIR.Program constructor', visitedNodes: 0};
  const prefix = rootTag.slice(0, -'Program'.length);
  const pending = [['Program', program, false]], active = new WeakMap(), visited = new WeakMap();
  let count = 0;
  while (pending.length) {
    const [kind, value, leave] = pending.pop();
    if (leave) { active.get(value)?.delete(kind); const kinds = visited.get(value) ?? new Set(); kinds.add(kind); visited.set(value, kinds); continue; }
    if (++count > budget.nodes) return {status: 'censored', reason: 'BIR validation node bound reached', visitedNodes: count - 1};
    if (kind === 'string' || kind === 'u32' || kind === 'nat' || kind === 'bool' || kind === 'opaque') {
      const ok = kind === 'string' ? typeof value === 'string' : kind === 'u32' ? u32(value) : kind === 'nat' ? nat(value) : kind === 'bool' ? typeof value === 'boolean' : object(value);
      if (!ok) return {status: 'invalid', reason: 'invalid scalar or opaque field: ' + kind, visitedNodes: count};
      continue;
    }
    if (!object(value)) return {status: 'invalid', reason: 'nonrecord ' + kind, visitedNodes: count};
    if (active.get(value)?.has(kind)) return {status: 'invalid', reason: 'cyclic ' + kind, visitedNodes: count};
    if (visited.get(value)?.has(kind)) continue;
    const kinds = active.get(value) ?? new Set(); kinds.add(kind); active.set(value, kinds);
    pending.push([kind, value, true]);
    const name = tag(value);
    if (kind[0] === '[') {
      if (name === 'Nil') continue;
      if (name !== 'Con') return {status: 'invalid', reason: 'non-Base List for ' + kind, visitedNodes: count};
      pending.push([kind, own(value, 'tail'), false], [kind.slice(1, -1), own(value, 'head'), false]);
    } else if (kind[0] === '?') {
      if (name === 'None') continue;
      if (name !== 'Some') return {status: 'invalid', reason: 'non-Base Maybe for ' + kind, visitedNodes: count};
      pending.push([kind.slice(1), own(value, 'value'), false]);
    } else if (kind === 'Primitive') {
      if (!PRIMITIVES.has(typeof name === 'string' && name.startsWith(prefix) ? name.slice(prefix.length) : null))
        return {status: 'unsupported', reason: 'unknown BIR primitive', visitedNodes: count};
    } else {
      const localName = typeof name === 'string' && name.startsWith(prefix) ? name.slice(prefix.length) : null;
      const fields = localName !== null && Object.hasOwn(SCHEMA[kind], localName) ? SCHEMA[kind][localName] : undefined;
      if (fields === undefined) return {status: 'unsupported', reason: 'unknown constructor for BIR.' + kind, visitedNodes: count};
      for (let index = fields.length - 1; index >= 0; index--) {
        const [field, fieldKind] = fields[index];
        pending.push([fieldKind, own(value, field), false]);
      }
    }
  }
  return {status: 'complete', visitedNodes: count, birTagPrefix: prefix, opaqueFields: ['ForeignDeclaration.span (source provenance only)']};
}
function* list(value) {
  for (let rest = value; tag(rest) === 'Con'; rest = own(rest, 'tail')) yield own(rest, 'head');
}
const maybe = value => tag(value) === 'Some' ? own(value, 'value') : undefined;

/**
 * Analyze an actual runtime BIR.Program. Root semantics come only from Ending:
 * Executable => first declaration named main; Library => every explicit Export.
 * requestManifests: [{document, namespace}] optionally identifies generated
 * scheduler declarations in this Program. namespace is the actual BIR module
 * key prefix (not inferred from a basename). These rows are declared provenance,
 * not an artifact-authentication replacement.
 */
export function analyzeDemand(program, options = {}) {
  const bound = limits(options), identity = provenance(options);
  const validation = validate(program, bound, options.birProgramTag);
  const common = {schemaVersion: 1, diagnosticOnly: true, acceptanceEvidence: false, provenance: identity, validation,
    limits: bound, familyArmPruningPermitted: false, transformationPerformed: false};
  if (validation.status !== 'complete') return {...common, status: validation.status,
    completeness: {inventory: false, executableReachability: false, layoutObligations: false},
    widening: ['Unknown or censored BIR means all executable and metadata obligations remain possible; no deadness conclusion.'],
    inventory: null, reachable: null, requestTags: null};

  const codes = new Map(), declarations = new Map(), constructors = new Map(), constructorIds = new Map(), families = new Map(), typeFunctions = new Map(), arms = new Map();
  const inventory = {codeRows: 0, declarationRows: 0, constructorRows: 0, familyRows: 0, typeFunctionRows: 0, familyArmRows: 0, duplicateCodeIds: 0, duplicateDeclarations: 0, duplicateConstructorKeys: 0, duplicateConstructorIds: 0, duplicateFamilyKeys: 0, duplicateTypeFunctionKeys: 0, duplicateArmKeys: 0};
  let rowCount = 0, rowCensored = false, firstConstructorKey = null, lastConstructorKey = null;
  const first = (map, key, row, duplicate) => { if (map.has(key)) inventory[duplicate] += 1; else map.set(key, row); };
  const tables = [['codes', codes, 'id', 'codeRows', 'duplicateCodeIds'], ['declarations', declarations, 'key', 'declarationRows', 'duplicateDeclarations'], ['constructors', constructors, 'key', 'constructorRows', 'duplicateConstructorKeys'], ['families', families, 'key', 'familyRows', 'duplicateFamilyKeys'], ['type_functions', typeFunctions, 'key', 'typeFunctionRows', 'duplicateTypeFunctionKeys']];
  for (const [field, map, key, count, duplicate] of tables) {
    for (const row of list(own(program, field))) {
      if (++rowCount > bound.rows) { rowCensored = true; break; }
      inventory[count] += 1; first(map, own(row, key), row, duplicate);
      if (field === 'constructors') {
        first(constructorIds, own(row, 'id'), row, 'duplicateConstructorIds');
        firstConstructorKey ??= own(row, 'key'); lastConstructorKey = own(row, 'key');
      }
      if (field === 'families') for (const arm of list(own(row, 'arms'))) {
        if (++rowCount > bound.rows) { rowCensored = true; break; }
        inventory.familyArmRows += 1;
        first(arms, own(arm, 'key'), {arm, family: own(row, 'key')}, 'duplicateArmKeys');
      }
      if (rowCensored) break;
    }
    if (rowCensored) break;
  }
  if (rowCensored) return {...common, status: 'censored', inventory: {...inventory, countsAreLowerBounds: true}, reachable: null,
    completeness: {inventory: false, executableReachability: false, layoutObligations: false},
    widening: ['Inventory row bound reached; all unscanned code, constructors and family arms remain possible.']};

  const codeNames = new Map();
  for (const [key, declaration] of declarations) if (simple(tag(declaration)) === 'FunctionDeclaration') {
    const id = own(declaration, 'code'); if (!codeNames.has(id)) codeNames.set(id, key);
  }
  const label = id => codeNames.get(id) ?? 'code#' + id;
  const reasons = new Set(), blockers = new Set(), edges = new Map(), codeFacts = new Map(), lazyFacts = new Map();
  let scanNodes = 0, scanCensored = false, edgeCensored = false;
  const addEdge = (from, kind, target) => {
    const key = JSON.stringify([from, kind, target]);
    if (edges.has(key)) return;
    if (edges.size >= bound.edges) { edgeCensored = true; return; }
    edges.set(key, {from, kind, target});
  };
  const newFacts = () => ({calls: new Set(), closures: new Set(), symbols: new Set(), constructors: new Set(), constructed: new Set(), tested: new Set(), descriptors: new Set(), unknownApply: 0});
  // All blocks/branches and both Region paths remain possible. No constructor
  // absence is interpreted as a proof about interprocedural request-tag flow.
  const scan = (body, owner) => {
    const facts = newFacts(), work = [body], seen = new WeakSet();
    const symbols = atom => { if (simple(tag(atom)) === 'Symbol') facts.symbols.add(own(atom, 'key')); };
    const args = values => { for (const arg of list(values)) symbols(own(arg, 'value')); };
    const useConstructor = (id, key, category) => {
      const row = constructorIds.get(id);
      if (row === undefined) blockers.add('missing constructor id ' + id);
      else {
        const actual = own(row, 'key'); facts.constructors.add(actual);
        if (category) facts[category].add(actual);
        if (key !== undefined && key !== actual) blockers.add('constructor id/key mismatch ' + id);
      }
    };
    while (work.length) {
      const block = work.pop();
      if (seen.has(block)) continue;
      seen.add(block);
      if (++scanNodes > bound.nodes) { scanCensored = true; break; }
      const kind = simple(tag(block));
      if (kind === 'Let') {
        const op = own(block, 'op'), opKind = simple(tag(op));
        switch (opKind) {
          case 'Copy': symbols(own(op, 'value')); break;
          case 'PrimitiveCall': args(own(op, 'args')); for (const descriptor of list(own(op, 'types'))) facts.descriptors.add(descriptor); break;
          case 'Closure': facts.closures.add(own(op, 'code')); args(own(op, 'captures')); addEdge(owner, 'closure-code', own(op, 'code')); break;
          case 'Direct': facts.calls.add(own(op, 'code')); args(own(op, 'args')); addEdge(owner, 'direct', own(op, 'code')); break;
          case 'Apply': symbols(own(op, 'fn')); symbols(own(own(op, 'arg'), 'value')); facts.unknownApply += 1; break;
          case 'LoadSymbol': facts.symbols.add(own(op, 'key')); break;
          case 'Construct': useConstructor(own(op, 'constructor'), own(op, 'tag'), 'constructed'); for (const field of list(own(op, 'fields'))) symbols(own(field, 'value')); break;
          case 'Project': useConstructor(own(op, 'constructor')); symbols(own(op, 'value')); break;
          case 'HasTag': useConstructor(own(op, 'constructor'), own(op, 'tag'), 'tested'); symbols(own(op, 'value')); break;
        }
        work.push(own(block, 'next'));
      } else if (kind === 'Return') symbols(own(block, 'value'));
      else if (kind === 'Branch') { symbols(own(block, 'condition')); work.push(own(block, 'no'), own(block, 'yes')); }
      else if (kind === 'Region') work.push(own(block, 'next'), own(block, 'body'));
      else if (kind === 'TailDirect') { facts.calls.add(own(block, 'code')); args(own(block, 'args')); addEdge(owner, 'tail-direct', own(block, 'code')); }
      else if (kind === 'TailApply') { symbols(own(block, 'fn')); symbols(own(own(block, 'arg'), 'value')); facts.unknownApply += 1; }
    }
    for (const symbol of facts.symbols) addEdge(owner, 'symbol-read', symbol);
    return facts;
  };
  for (const [id, code] of codes) { codeFacts.set(id, scan(own(code, 'body'), 'code#' + id)); if (scanCensored) break; }
  if (!scanCensored) for (const [key, declaration] of declarations) if (simple(tag(declaration)) === 'LazyDeclaration') {
    lazyFacts.set(key, scan(own(declaration, 'body'), 'declaration:' + key)); if (scanCensored) break;
  }
  if (inventory.duplicateCodeIds || inventory.duplicateConstructorIds) blockers.add('duplicate numeric identity: first row retained, ambiguous references widen all');
  if (scanCensored) blockers.add('code traversal node bound reached');
  if (edgeCensored) blockers.add('relationship output bound reached (reachability sets retained)');

  const reachedCodes = new Set(), reachedDeclarations = new Set(), codeConstructors = new Set(), constructed = new Set(), tested = new Set(), descriptorRoots = new Set(), roots = [], queue = [];
  let allCode = false, allLayout = false;
  const enqueueCode = id => { if (!codes.has(id)) { blockers.add('missing code id ' + id); return; } if (!reachedCodes.has(id)) { reachedCodes.add(id); queue.push(['code', id]); } };
  const enqueueDeclaration = key => { if (!declarations.has(key)) { blockers.add('missing declaration ' + key); return; } if (!reachedDeclarations.has(key)) { reachedDeclarations.add(key); queue.push(['declaration', key]); } };
  const widenCode = reason => {
    reasons.add(reason); if (allCode) return; allCode = true;
    for (const id of codes.keys()) enqueueCode(id);
    for (const key of declarations.keys()) enqueueDeclaration(key);
  };
  const ending = own(program, 'ending');
  if (simple(tag(ending)) === 'Executable') {
    roots.push({kind: 'main', key: 'main'}); enqueueDeclaration('main'); descriptorRoots.add(own(ending, 'main_type'));
  } else for (const exported of list(own(ending, 'exports'))) {
    const key = own(exported, 'key'), entry = maybe(own(exported, 'entry'));
    roots.push({kind: 'export', key, code: entry ? own(entry, 'code') : null});
    if (entry) enqueueCode(own(entry, 'code')); else enqueueDeclaration(key);
    for (const descriptor of list(own(exported, 'parameter_types'))) descriptorRoots.add(descriptor);
    descriptorRoots.add(own(exported, 'result'));
  }
  const applyFacts = facts => {
    if (!facts) return;
    for (const id of facts.calls) enqueueCode(id);
    for (const id of facts.closures) enqueueCode(id);
    for (const key of facts.symbols) enqueueDeclaration(key);
    for (const key of facts.constructors) codeConstructors.add(key);
    for (const key of facts.constructed) constructed.add(key);
    for (const key of facts.tested) tested.add(key);
    for (const descriptor of facts.descriptors) descriptorRoots.add(descriptor);
    if (facts.unknownApply) { widenCode('reachable higher-order Apply/TailApply: no interprocedural closure-flow proof; all code/declarations retained'); allLayout = true; }
  };
  if (blockers.size) { widenCode('incomplete or ambiguous executable inventory; retain every code/declaration'); allLayout = true; }
  for (let cursor = 0; cursor < queue.length; cursor++) {
    const [kind, key] = queue[cursor];
    if (kind === 'code') applyFacts(codeFacts.get(key));
    else {
      const declaration = declarations.get(key), declarationKind = simple(tag(declaration));
      if (declarationKind === 'FunctionDeclaration') enqueueCode(own(declaration, 'code'));
      else if (declarationKind === 'LazyDeclaration') applyFacts(lazyFacts.get(key));
      else if (declarationKind === 'ForeignDeclaration') {
        widenCode('reachable foreign declaration: callbacks/returned higher-order values are opaque; retain every code/declaration'); allLayout = true;
        for (const descriptor of list(own(declaration, 'parameter_types'))) descriptorRoots.add(descriptor);
        descriptorRoots.add(own(declaration, 'result'));
      }
    }
    if (blockers.size && !allCode) { widenCode('unresolved executable references; retain every code/declaration'); allLayout = true; }
  }
  // Retaining a foreign ABI also retains its type obligations even when its
  // executable declaration is outside the main/export call graph.
  for (const declaration of declarations.values()) if (simple(tag(declaration)) === 'ForeignDeclaration') {
    for (const descriptor of list(own(declaration, 'parameter_types'))) descriptorRoots.add(descriptor);
    descriptorRoots.add(own(declaration, 'result'));
  }

  const layoutConstructors = new Set(codeConstructors), layoutFamilies = new Set(), layoutTypeFunctions = new Set(), runtimeMissing = [], layoutWork = [], seenDescriptors = new WeakSet();
  for (const key of RUNTIME_CTORS) { if (constructors.has(key)) layoutConstructors.add(key); else runtimeMissing.push(key); }
  if (runtimeMissing.length) blockers.add('required C runtime constructor aliases absent (not a valid-output verdict)');
  const enqueueFamily = key => {
    if (layoutFamilies.has(key)) return;
    const family = families.get(key); if (!family) return;
    layoutFamilies.add(key);
    // Keep ALL source arms. Type layout uses the union/packed shape, not just
    // constructed rows; pruning rows never licenses removing family arms.
    for (const arm of list(own(family, 'arms'))) {
      const armKey = own(arm, 'key');
      if (constructors.has(armKey)) layoutConstructors.add(armKey);
      for (const field of list(own(arm, 'fields'))) layoutWork.push(own(field, 'ty'));
    }
  };
  for (const key of layoutConstructors) {
    const authority = arms.get(key);
    if (authority) {
      enqueueFamily(authority.family);
      for (const field of list(own(authority.arm, 'fields'))) layoutWork.push(own(field, 'ty'));
    }
    else { allLayout = true; blockers.add('constructor has no declared family arm: ' + key); }
  }
  for (const descriptor of descriptorRoots) layoutWork.push(descriptor);
  let layoutNodes = 0;
  while (layoutWork.length && !allLayout) {
    const descriptor = layoutWork.pop();
    if (seenDescriptors.has(descriptor)) continue;
    seenDescriptors.add(descriptor);
    if (++layoutNodes > bound.nodes) { allLayout = true; blockers.add('descriptor demand node bound reached'); break; }
    const name = simple(tag(descriptor)), key = own(descriptor, 'key');
    if (name === 'DescriptorRef' || name === 'DescriptorConstructor' || name === 'DescriptorNamedFill' || name === 'DescriptorNamedPlus' || name === 'DescriptorConstructorPattern') {
      if (families.has(key)) enqueueFamily(key);
      else if (typeFunctions.has(key)) {
        if (!layoutTypeFunctions.has(key)) { layoutTypeFunctions.add(key); layoutWork.push(own(typeFunctions.get(key), 'body')); }
      } else if (arms.has(key)) { layoutConstructors.add(key); enqueueFamily(arms.get(key).family); }
      else { allLayout = true; reasons.add('unresolved descriptor name; retain all constructor/family/type-function metadata'); }
    }
    if (['DescriptorApplication', 'DescriptorLambda', 'DescriptorSubstitution', 'DescriptorLocal', 'DescriptorMatch', 'DescriptorFill', 'DescriptorPlus', 'DescriptorNamedFill', 'DescriptorNamedPlus', 'DescriptorParameter'].includes(name)) {
      allLayout = true; reasons.add('dependent/higher-order descriptor requires NF/environment reasoning not performed by census; retain all metadata');
    }
    const fields = SCHEMA.Descriptor[name] ?? SCHEMA.DescriptorPattern[name] ?? [];
    for (const [field, kind] of fields) {
      if (kind === 'Descriptor' || kind === 'DescriptorPattern') layoutWork.push(own(descriptor, field));
      else if (kind === '[Descriptor]' || kind === '[DescriptorPattern]') for (const item of list(own(descriptor, field))) layoutWork.push(item);
    }
  }
  if (allLayout) {
    reasons.add('layout obligation widening retains every constructor row, every family arm and every type-function definition');
    for (const key of constructors.keys()) layoutConstructors.add(key);
    for (const key of families.keys()) layoutFamilies.add(key);
    for (const key of typeFunctions.keys()) layoutTypeFunctions.add(key);
  }

  const requestRows = new Map(), dispatchers = [], manifestIssues = [];
  for (const entry of (options.requestManifests ?? []).slice(0, 16)) {
    const document = entry?.document, namespace = entry?.namespace;
    if (!document || typeof namespace !== 'string') { manifestIssues.push('request manifest missing document or actual BIR namespace'); continue; }
    const qualify = name => namespace ? namespace + '.' + name : name;
    const coverage = document.coverage;
    if (!Array.isArray(coverage) || coverage.length > bound.rows) { manifestIssues.push('missing or oversized request coverage'); continue; }
    const owners = new Map();
    for (const row of (document.canonicalComposition?.declarations ?? []).slice(0, bound.rows)) if (row.kind === 'def') {
      if (owners.has(row.name)) owners.set(row.name, null); else owners.set(row.name, row);
    }
    for (const row of coverage) {
      if (typeof row.request !== 'string' || typeof row.stepBody !== 'string') continue;
      const owner = owners.get(row.name), key = qualify(row.request);
      if (!constructors.has(key)) continue;
      if (requestRows.has(key)) { manifestIssues.push('ambiguous request identity ' + key); requestRows.set(key, null); continue; }
      requestRows.set(key, {key, handler: qualify(row.stepBody), source: owner?.source ?? null, canonicalName: owner?.canonicalName ?? null,
        composedDeclarationSha256: owner?.composedDeclarationSha256 ?? null});
    }
    const dispatcherKey = typeof document.nativeChunk?.rawStep === 'string' ? qualify(document.nativeChunk.rawStep) : null;
    if (dispatcherKey) {
      const declaration = declarations.get(dispatcherKey), id = own(declaration, 'code');
      dispatchers.push({key: dispatcherKey, present: declaration !== undefined, reachable: reachedDeclarations.has(dispatcherKey) || reachedCodes.has(id), code: u32(id) ? id : null,
        declaredGroups: Array.isArray(document.requestGroups) ? document.requestGroups.length : null,
        reason: 'step_one matches every RequestGroup; each group handler matches every request constructor and statically calls its stepBody (checker_core_step_lower.ts:2414-2423). Ordinary graph reachability follows every branch; only a proven finite incoming-tag flow can narrow it.'});
    }
  }
  // Isolate ordinary static-dispatch demand from the separate higher-order
  // widening. This is a finite graph census, not an execution-frequency claim.
  let dispatchVisits = 0;
  for (const dispatcher of dispatchers) {
    const seen = new Set(), work = dispatcher.code === null ? [] : [dispatcher.code];
    let censored = false, unresolved = false;
    while (work.length) {
      const id = work.pop();
      if (seen.has(id)) continue;
      if (++dispatchVisits > bound.nodes) { censored = true; break; }
      seen.add(id);
      const facts = codeFacts.get(id);
      if (!facts) { unresolved = true; continue; }
      for (const callee of facts.calls) work.push(callee);
      for (const key of facts.symbols) {
        const declaration = declarations.get(key);
        if (simple(tag(declaration)) === 'FunctionDeclaration') work.push(own(declaration, 'code'));
      }
    }
    const handlers = [];
    for (const row of requestRows.values()) if (row && seen.has(own(declarations.get(row.handler), 'code'))) handlers.push(row.key);
    dispatcher.staticCallReachableCodes = summary([...seen].map(label), bound.examples);
    dispatcher.staticCallReachableRequestHandlers = summary(handlers, bound.examples);
    dispatcher.staticClosureStatus = censored || scanCensored ? 'censored' : unresolved ? 'unresolved-reference' : 'complete-direct-and-symbol-edges';
    dispatcher.staticClosureExcludes = ['higher-order Apply targets', 'closure invocation', 'lazy result evaluation'];
  }
  const requestKeys = [...requestRows.keys()], requestedConstructed = requestKeys.filter(key => constructed.has(key)), requestedTested = requestKeys.filter(key => tested.has(key));
  const opportunities = requestKeys.filter(key => !constructed.has(key));
  const requestSummary = values => summary(values, bound.examples);
  const reachableEdges = [...edges.values()].filter(edge => edge.from.startsWith('code#') ? reachedCodes.has(Number(edge.from.slice(5))) : reachedDeclarations.has(edge.from.slice('declaration:'.length)));
  const countKind = kind => reachableEdges.reduce((count, edge) => count + Number(edge.kind === kind), 0);
  return {...common, status: scanCensored ? 'censored' : blockers.size ? 'conservative-with-blockers' : 'complete-conservative',
    completeness: {inventory: true, executableReachability: !scanCensored, executableReachabilityMeaning: 'conservative may-reach upper bound, not exact liveness', layoutObligations: !scanCensored,
      layoutObligationsMeaning: 'conservative symbolic obligations, not evaluated physical layouts', relationships: !edgeCensored && !scanCensored, exactRuntimeTagFlow: false},
    inventory: {...inventory, constructorRowEndpoints: {first: firstConstructorKey, last: lastConstructorKey},
      codes: summary([...codes.keys()].map(label), bound.examples), declarations: summary(declarations.keys(), bound.examples), constructors: summary(constructors.keys(), bound.examples), families: summary(families.keys(), bound.examples), typeFunctions: summary(typeFunctions.keys(), bound.examples)},
    roots: summary(roots, bound.examples),
    reachable: {codes: summary([...reachedCodes].map(label), bound.examples), declarations: summary(reachedDeclarations, bound.examples), executableConstructorRoots: summary(codeConstructors, bound.examples), constructed: summary(constructed, bound.examples), tested: summary(tested, bound.examples), widenedToAllCode: allCode},
    relationships: {basis: 'actual BIR Direct/TailDirect/Closure/Symbol operands; no host-boundary inference',
      totalUnique: edgeCensored || scanCensored ? null : edges.size, retainedUnique: edges.size,
      reachableUnique: edgeCensored || scanCensored ? null : reachableEdges.length, countsAreLowerBounds: edgeCensored || scanCensored,
      direct: countKind('direct'), tailDirect: countKind('tail-direct'), closureCode: countKind('closure-code'), symbolRead: countKind('symbol-read'), examples: reachableEdges.slice(0, bound.examples), examplesTruncated: reachableEdges.length > bound.examples},
    layout: {currentGloballyForcedCidRows: inventory.constructorRows, currentGloballyForcedConstructorKeys: summary(constructors.keys(), bound.examples),
      globalRootProof: 'c_backend.bend:995-1004,1042-1051 traverses every ConstructorLayout and requires cid_node_arity; c_backend_layout.bend:903-910 precomputes every constructor node.',
      potentiallyDemandRefinedConstructorRoots: summary(layoutConstructors, bound.examples), retainedFamilies: summary(layoutFamilies, bound.examples), retainedTypeFunctions: summary(layoutTypeFunctions, bound.examples),
      runtimeConstructorRoots: RUNTIME_CTORS, missingRuntimeConstructors: runtimeMissing,
      foreignCidObligations: summary([...declarations].filter(([, value]) => simple(tag(value)) === 'ForeignDeclaration').map(([key]) => key), bound.examples),
      foreignPolicy: 'retain every foreign declaration and staged runtime Cid obligation; no foreign ABI/body analysis',
      widenedToAllMetadata: allLayout, firstDeclarationAuthority: true, familyArms: 'preserve every declared arm of each retained family in source order; constructor-row demand is not permission for family-arm pruning',
      validOutputProven: false, physicalWordCountsComputed: false},
    requestTags: {identityBasis: 'exact BIR constructor key joined to caller-supplied canonical manifest coverage; source proof, not sampled tag absence',
      inventory: requestSummary(requestKeys), constructedInMayReachCode: requestSummary(requestedConstructed), testedInMayReachCode: requestSummary(requestedTested),
      finiteCandidateTags: requestSummary(requestedConstructed), noVisibleConstructionCandidates: requestSummary(opportunities),
      specializationStatus: !requestKeys.length ? 'missing-request-manifest-or-matching-BIR-constructors'
        : allCode || allLayout || blockers.size || manifestIssues.length ? 'blocked-by-unknown-flow' : 'requires-interprocedural-tag-flow-proof',
      absentConstructionIsImpossible: false, sampledTagsUsedForDeadness: false, dispatchers: dispatchers.slice(0, bound.examples),
      identityExamples: [...requestRows.values()].filter(Boolean).slice(0, bound.examples), blockers: manifestIssues.slice(0, bound.examples),
      proofRequired: 'track request constructors through parameters, fields, return values, closures and foreign escapes; unknown flow widens to the entire request family. The current census does not eliminate dispatcher branches.'},
    widening: [...reasons].slice(0, bound.examples), blockers: summary(blockers, bound.examples),
    observation: {codeNodesVisited: scanNodes, descriptorNodesVisited: layoutNodes, allocationCounts: 'not observed', internal64Transitions: 'not observed'},
  };
}

/**
 * Bounded, read-only seam capture. `manifest` is loadStageManifests(...) output.
 * birProgramTag MUST be derived from the authenticated BIR import/tag encoding
 * (same rule as SourceFile, with local constructor Program), never a suffix guess.
 * The first actual Program is analyzed synchronously and then released: no Run,
 * closure, source arena or Program reference is retained in the returned report.
 */
export function createDemandCapture(options = {}) {
  const manifest = options.manifest;
  const maxDepth = bounded(options.maxBoundDepth, 64, 1024), maxFields = bounded(options.maxArgumentFields, 64, 1024);
  const maxCaptures = bounded(options.maxCaptures, 1, 4), maxBoundaries = bounded(options.maxBoundaries, 1000000, 10000000);
  const expectedTag = options.birProgramTag;
  const results = [], seenPrograms = new WeakSet(), failures = new Set();
  const counts = {boundaries: 0, pending: 0, direct: 0, traceSpans: 0, argumentFields: 0, programCandidates: 0, invalidCandidates: 0, censoredBoundaries: 0, unverifiedBoundaries: 0};
  const missingRoute = 'A Program must be visible as a Pending request data argument (e.g. authenticated c_backend.plan_make), or explicitly exposed by a separately approved passive diagnostic data carrier at that boundary. RunSpan.next and Direct.invoke capture values in opaque closures and are never forced. Quantum64 can skip Pending between host boundaries.';
  const accept = (candidate, producer) => {
    if (tag(candidate) !== expectedTag || seenPrograms.has(candidate) || results.length >= maxCaptures) return;
    seenPrograms.add(candidate); counts.programCandidates += 1;
    const result = analyzeDemand(candidate, {...options.analysisOptions, producerIdentity: options.producerIdentity, inputSha256: options.inputSha256, birProgramTag: expectedTag});
    if (result.validation.status === 'invalid' || result.validation.status === 'unsupported') {
      counts.invalidCandidates += 1; failures.add('Program-shaped argument failed BIR structural validation'); return;
    }
    results.push({capture: producer, analysis: result});
  };
  const scanArguments = (record, producer) => {
    if (!object(record)) return;
    const prototype = Object.getPrototypeOf(record);
    if (prototype !== Object.prototype && prototype !== null) { failures.add('nonplain request argument record'); return; }
    if (tag(record) === expectedTag) { accept(record, producer); return; }
    // Bounded property enumeration: descriptors avoid invoking getters. Do not
    // descend into argument objects, lists, arenas, closures or runtime stacks.
    let scanned = 0;
    for (const key in record) {
      if (++scanned > maxFields) { counts.censoredBoundaries += 1; failures.add('request argument field bound reached'); break; }
      if (!Object.hasOwn(record, key) || key === '$') continue;
      counts.argumentFields += 1;
      accept(own(record, key), {...producer, argumentField: key});
    }
  };
  return {
    observeRun(run) {
      if (results.length >= maxCaptures) return;
      if (++counts.boundaries > maxBoundaries) { counts.censoredBoundaries += 1; return; }
      if (typeof expectedTag !== 'string' || simple(expectedTag) !== 'Program') { failures.add('missing source-derived exact BIR.Program tag'); return; }
      const runTag = tag(run);
      if (typeof runTag !== 'string') { failures.add('nonrecord Run'); return; }
      const suffix = simple(runTag), namespace = runTag.includes('.') ? runTag.slice(0, runTag.lastIndexOf('.')) : null;
      const table = traceTableFor(manifest, namespace);
      if (table.status !== 'verified' || table.artifactBinding?.status !== 'verified') { counts.unverifiedBoundaries += 1; failures.add('Run has no verified canonical manifest/artifact binding'); return; }
      const qualify = name => namespace === null ? name : namespace + '.' + name;
      if (suffix === 'EmitterRunSpan') {
        counts.traceSpans += 1;
        const capture = options.programCapture;
        if (!capture) return;
        const events = typedTraceEvents(run, table);
        const payload = own(run, capture.runField);
        if (tag(payload) !== qualify(capture.constructor)) return;
        const root = table.roots.find(row => row.site === capture.site && row.status === 'verified');
        if (!root || events.status !== 'ok' || events.events.length !== 1
          || events.events[0].kind !== 'begin' || events.events[0].site !== root.site) {
          failures.add('passive Program carrier lacks its authenticated Begin boundary'); return;
        }
        accept(own(payload, 'program'), {measurement: 'engine-emitted-passive-Program-boundary',
          boundary: counts.boundaries - 1, source: root.source, canonicalName: root.canonicalName,
          canonicalDeclarationSha256: root.canonicalDeclarationSha256,
          generationManifestSha256: table.generationManifestSha256});
        return;
      }
      if (runTag !== qualify('EmitterRunState')) return;
      let progress = own(run, 'progress');
      const seen = new WeakSet();
      for (let depth = 0; depth <= maxDepth; depth++) {
        if (!object(progress) || seen.has(progress)) { failures.add('malformed or cyclic Progress'); return; }
        seen.add(progress);
        const progressTag = tag(progress);
        if (progressTag === qualify('EmitterBound')) { progress = own(progress, 'inner'); continue; }
        if (progressTag === qualify('EmitterPending')) {
          counts.pending += 1;
          const envelope = own(progress, 'request'), request = own(envelope, 'request'), requestTag = tag(request);
          if (typeof requestTag !== 'string') { failures.add('Pending has no visible request record'); return; }
          const envelopeTag = tag(envelope), envelopeName = simple(envelopeTag);
          if (typeof envelopeName !== 'string' || !/^EmitterRequestGroup_[0-9]+$/.test(envelopeName)
            || envelopeTag !== qualify(envelopeName)) { failures.add('invalid Pending request envelope'); return; }
          const root = table.roots.find(row => row.status === 'verified'
            && (table.tagEncoding === 'canonical-compiled-js' ? simple(row.request) : row.request) === requestTag);
          // Only canonical, authenticated trace roots are admitted as producers;
          // an arbitrary record with matching field names is not BIR evidence.
          if (!root) return;
          scanArguments(request, {measurement: 'sampled-visible-Pending-argument', boundary: counts.boundaries - 1,
            request: requestTag, source: root.source, canonicalName: root.canonicalName,
            canonicalDeclarationSha256: root.canonicalDeclarationSha256, generationManifestSha256: table.generationManifestSha256});
          return;
        }
        if (progressTag === qualify('EmitterDirect')) {
          counts.direct += 1;
          // Its erased request witness cannot authenticate the callable identity.
          // Current generated arguments are False{}, while actual arguments live
          // inside invoke. Record a visible candidate but never attribute/analyze
          // it without a canonical request identity.
          const arguments_ = own(progress, 'arguments');
          if (tag(arguments_) === expectedTag) failures.add('visible Direct Program lacks an authenticated nonerased request identity');
          return;
        }
        return;
      }
      counts.censoredBoundaries += 1; failures.add('Bound wrapper depth bound reached');
    },
    report() {
      return {schemaVersion: 1, diagnosticOnly: true, acceptanceEvidence: false,
        status: results.some(row => row.analysis.validation.status === 'complete') ? 'captured'
          : results.length ? 'captured-censored' : 'missing-prerequisite', provenance: provenance(options),
        measurement: results.some(row => row.capture.measurement === 'engine-emitted-passive-Program-boundary')
          ? 'explicit engine Program boundary; remaining observations are bounded host samples'
          : 'bounded host-boundary sample, not complete transition or allocation census',
        counts: {...counts}, limits: {maxBoundDepth: maxDepth, maxArgumentFields: maxFields, maxCaptures, maxBoundaries},
        failures: [...failures].slice(0, 24), captures: results.slice(), missingPrerequisite: results.length ? null : missingRoute,
        invokesClosures: false, absentSampledTagsAreImpossible: false,
        sourceProof: ['backend_ir.bend:243-244', 'c_backend.bend:466-478', 'checker_core_step_lower.ts:2372,2427-2445']};
    },
  };
}
