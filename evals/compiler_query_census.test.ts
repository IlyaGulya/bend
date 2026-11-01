import {test, expect} from 'bun:test';
import {createQueryCensus} from './compiler_query_census.mjs';

const nil = {$: 'Nil'};
const list = (items: any[]): any => items.reduceRight((tail, head) => ({$: 'Con', head, tail}), nil);
const context = {$: 'NF.NfContext', families: {$: 'MTip'}, type_functions: {$: 'MTip'}};
const descriptor = {$: 'BIR.DescriptorRef', key: 'Box', args: nil};
const closure = {$: 'NF.NfClosure', quantity: {$: 'None'},
  body: {$: 'BIR.DescriptorParameter', index: 0n},
  env: list([{$: 'NF.NfType', key: 'A', args: nil}])};
const input = (): any => ({context, descriptor: structuredClone(descriptor),
  env: list([structuredClone(closure)]), level: 0n, fuel: 1024n});
const make = (options = {}) => createQueryCensus({immutableData: true, ...options});

test('equal Data and native Nat encodings share identity, ignoring the transport tag', () => {
  const census = make();
  expect(census.observe('nf', input()).repeated).toBe(false);
  const copy = {...input(), level: 0, fuel: 1024, $: 'EmitterTraceNfQuery'};
  expect(census.observe('nf', copy).repeated).toBe(true);
  expect(census.report().kinds.nf.exactDistinct).toBe(1);
  expect(census.report().kinds.nf.exactRepeats).toBe(1);
});

for (const [name, mutate] of [
  ['fuel', (query: any) => { query.fuel = 1023n; }],
  ['output level', (query: any) => { query.level = 1n; }],
  ['closure body', (query: any) => { query.env.head.body.index = 1n; }],
  ['closure capture', (query: any) => { query.env.head.env.head.key = 'B'; }],
  ['closure quantity', (query: any) => { query.env.head.quantity = {$: 'Some', value: {$: 'Many'}}; }],
  ['descriptor', (query: any) => { query.descriptor.key = 'Other'; }],
] as const) {
  test(`NF identity retains ${name}`, () => {
    const census = make();
    census.observe('nf', input());
    const next = input();
    mutate(next);
    expect(census.observe('nf', next).repeated).toBe(false);
    expect(census.report().kinds.nf.exactDistinct).toBe(2);
  });
}

test('equal context copies are conservatively partitioned, not hidden as different structures', () => {
  const census = make();
  census.observe('nf', input());
  expect(census.observe('nf', {...input(), context: structuredClone(context)}).repeated).toBe(false);
  expect(census.report().kinds.nf.structurallyDistinctContexts).toBe(1);
  expect(census.report().kinds.nf.contextObjectCount).toBe(2);
});

test('binder levels in environments participate in identity', () => {
  const census = make();
  const first = {...input(), env: list([{$: 'NF.NfBinder', level: 1n}])};
  census.observe('nf', first);
  expect(census.observe('nf', {...first, env: list([{$: 'NF.NfBinder', level: 2n}])}).repeated).toBe(false);
});

test('reach retains target and ordered seen history', () => {
  const census = make();
  const reach = () => ({context, descriptor: structuredClone(descriptor), env: nil,
    target: 'Root', seen: list(['A', 'B']), fuel: 8n});
  census.observe('reach', reach());
  expect(census.observe('reach', {...reach(), target: 'Other'}).repeated).toBe(false);
  expect(census.observe('reach', {...reach(), seen: list(['B', 'A'])}).repeated).toBe(false);
  expect(census.report().kinds.reach.exactDistinct).toBe(3);
});

test('accessors are unsupported without invoking them or counting partial keys', () => {
  let calls = 0;
  const query = input();
  Object.defineProperty(query.descriptor, 'key', {get() { calls++; throw Error('executed accessor'); }});
  const census = make();
  expect(census.observe('nf', query).status).toBe('unsupported');
  expect(calls).toBe(0);
  expect(census.report().kinds.nf.exactDistinct).toBe(0);
  census.observe('nf', input());
  expect(census.report().kinds.nf.classified).toBe(1);
  expect(census.report().fullyClassifiedPrefix.observations).toBe(0);
});

test('proxy traps are never invoked', () => {
  let calls = 0;
  const query = {...input(), env: new Proxy({}, {ownKeys() { calls++; throw Error('executed proxy'); }})};
  const census = make();
  expect(census.observe('nf', query).status).toBe('unsupported');
  expect(calls).toBe(0);
  expect(census.report().kinds.nf.exactDistinct).toBe(0);
});

test('cycles are not classified as finite immutable Data', () => {
  const query = input();
  query.env = {$: 'Con', head: closure};
  query.env.tail = query.env;
  const census = make();
  expect(census.observe('nf', query).status).toBe('unsupported');
  expect(census.report().kinds.nf.exactDistinct).toBe(0);
});

test('query exhaustion permanently censors even later known repeats', () => {
  const census = make({maxQueries: 1});
  census.observe('nf', input());
  expect(census.observe('nf', {...input(), fuel: 3n}).status).toBe('censored');
  expect(census.observe('nf', input()).status).toBe('censored');
  const report = census.report();
  expect(report.kinds.nf.classified).toBe(1);
  expect(report.kinds.nf.exactDistinct).toBe(1);
  expect(report.kinds.nf.exactRepeats).toBe(0);
  expect(report.fullyClassifiedPrefix.observations).toBe(1);
});

test('incomplete structural interning does not classify a query', () => {
  const census = make({maxNodes: 1});
  expect(census.observe('nf', input()).status).toBe('censored');
  expect(census.report().kinds.nf.classified).toBe(0);
});

test('mutable mode rescans changed inputs rather than returning stale weak identities', () => {
  const census = make({immutableData: false});
  const query = input();
  census.observe('nf', query);
  query.descriptor.key = 'Mutated';
  expect(census.observe('nf', query).repeated).toBe(false);
  expect(census.report().kinds.nf.exactDistinct).toBe(2);
});
