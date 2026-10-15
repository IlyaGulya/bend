import {createHash} from 'node:crypto';

// Source-only audit of CheckerCore's current first-order, one-line def signatures.
// This does not parse/check/emit target Bend programs or replace semantic stages.
const sourcePath = process.argv[2] ?? 'checkpoints/checker_core_slice.bend';
const source = await Bun.file(sourcePath).text();
const masked = source.replace(/"(?:\\.|[^"\\])*"/g, s => s.replace(/[^\n]/g, ' ')).replace(/(?:#|\/\/)[^\n]*/g, s => ' '.repeat(s.length));
const starts = [...masked.matchAll(/^def ([A-Za-z_][A-Za-z_0-9]*)\(/gm)];
const names = new Set(starts.map(m => m[1]));
if (names.size !== starts.length) throw Error('Duplicate definition names');
const definitions = starts.map((m, i) => {
  const begin = m.index!;
  const end = starts[i + 1]?.index ?? source.length;
  const text = masked.slice(begin, end);
  const body = text.indexOf(':\n');
  if (body < 0 || text.slice(0, body).includes('\n')) throw Error('Unsupported def signature: ' + m[1]);
  for (const parameter of text.slice(0, body).matchAll(/\b([A-Za-z_][A-Za-z_0-9]*)\s*:/g)) {
    if (names.has(parameter[1])) throw Error('Local definition shadowed by parameter: ' + parameter[1]);
  }
  const references: {name: string; line: number}[] = [];
  for (const token of text.matchAll(/\b[A-Za-z_][A-Za-z_0-9]*\b/g)) {
    const pos = token.index!;
    if (pos <= body || !names.has(token[0]) || text[pos - 1] === '.') continue;
    if (!/^\s*\(/.test(text.slice(pos + token[0].length))) {
      throw Error('Non-call local identifier needs binding-aware analysis: ' + m[1] + '/' + token[0]);
    }
    references.push({name: token[0], line: source.slice(0, begin + pos).split('\n').length});
  }
  return {name: m[1], sourceOrder: i + 1, line: source.slice(0, begin).split('\n').length,
    direct: [...new Set(references.map(r => r.name))], references};
});
const byName = new Map(definitions.map(d => [d.name, d]));
let counter = 0;
const ids = new Map<string, number>(), low = new Map<string, number>(), stack: string[] = [], active = new Set<string>();
const components: string[][] = [];
function visit(name: string) {
  ids.set(name, counter); low.set(name, counter++); stack.push(name); active.add(name);
  for (const ref of byName.get(name)!.direct) {
    if (!ids.has(ref)) {visit(ref); low.set(name, Math.min(low.get(name)!, low.get(ref)!));}
    else if (active.has(ref)) low.set(name, Math.min(low.get(name)!, ids.get(ref)!));
  }
  if (low.get(name) === ids.get(name)) {
    const component: string[] = []; let member: string;
    do {member = stack.pop()!; active.delete(member); component.push(member);} while (member !== name);
    components.push(component.sort((a,b) => byName.get(a)!.sourceOrder - byName.get(b)!.sourceOrder));
  }
}
for (const d of definitions) if (!ids.has(d.name)) visit(d.name);
components.sort((a,b) => byName.get(a[0])!.sourceOrder - byName.get(b[0])!.sourceOrder);
const mutual = components.filter(c => c.length > 1);
const componentOf = new Map(components.flatMap((c,i) => c.map(n => [n,i] as const)));
// Independent transitive-reachability check of the complete SCC partition.
const reachable = new Map<string, Set<string>>();
for (const d of definitions) {
  const seen = new Set<string>(), pending = [...d.direct];
  while (pending.length) {const n = pending.pop()!; if (!seen.has(n)) {seen.add(n); pending.push(...byName.get(n)!.direct);}}
  reachable.set(d.name, seen);
}
for (const a of definitions) for (const b of definitions) {
  const same = a.name === b.name || (reachable.get(a.name)!.has(b.name) && reachable.get(b.name)!.has(a.name));
  if (same !== (componentOf.get(a.name) === componentOf.get(b.name))) throw Error('SCC verification mismatch');
}
const rows = definitions.map(d => ({...d,
  earlier: d.direct.filter(r => byName.get(r)!.sourceOrder < d.sourceOrder),
  later: d.direct.filter(r => byName.get(r)!.sourceOrder > d.sourceOrder),
  selfRecursive: d.direct.includes(d.name),
  nonSingletonSCC: mutual.findIndex(c => c.includes(d.name)) + 1 || null}));
const forward = rows.flatMap(d => d.later.map(to => ({from: d.name, to,
  fromOrder: d.sourceOrder, toOrder: byName.get(to)!.sourceOrder,
  lines: d.references.filter(r => r.name === to).map(r => r.line),
  classification: componentOf.get(d.name) === componentOf.get(to) ? 'C: mutual SCC' : 'A: acyclic inter-SCC'})));
const report = {sourcePath, sourceSha256: createHash('sha256').update(source).digest('hex'),
  method: 'String/comment masking; unique def names; bare local identifiers only; qualified imported names excluded; rejects parameter shadowing, non-call local identifiers and unsupported signatures; Tarjan verified against independent all-pairs mutual reachability.',
  sourceOrderBase: 1, definitionCount: rows.length, forwardEdgeCount: forward.length,
  acyclicForwardEdgeCount: forward.filter(e => e.classification.startsWith('A')).length,
  cyclicForwardEdgeCount: forward.filter(e => e.classification.startsWith('C')).length,
  selfRecursiveCount: rows.filter(d => d.selfRecursive).length,
  nonSingletonSCCCount: mutual.length,
  rootReachableDefinitions: rows.filter(d => d.name === 'check_modules' || reachable.get('check_modules')!.has(d.name)).length,
  rootUnreachableDefinitions: rows.filter(d => d.name !== 'check_modules' && !reachable.get('check_modules')!.has(d.name)).map(d => d.name),
  definitions: rows, forwardEdges: forward,
  nonSingletonSCCs: mutual.map((members,i) => ({id:i+1,members,
    internalEdges: members.flatMap(from => byName.get(from)!.direct.filter(to => to !== from && members.includes(to)).map(to => ({from,to,lines:byName.get(from)!.references.filter(r=>r.name===to).map(r=>r.line)})))}))};
console.log(JSON.stringify(report, null, 2));
