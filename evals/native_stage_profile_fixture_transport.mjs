#!/usr/bin/env node
// Diagnostic transport only: render a canonical BIR.Program plus its real C
// source bundle as a Bend data module. No checker/renderer logic is duplicated.
import {readFileSync, writeFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {dirname, join, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const [birPath, sourcesPath, runtimePath, outPath, ...extra] = process.argv.slice(2);
if (!birPath || !sourcesPath || !runtimePath || !outPath) throw Error('usage: bir.json sources.json runtime.c out.bend [--source=FILE --checked=FILE --component=FILE]');

function splitTop(text) {
  const out = []; let depth = 0, start = 0;
  for (let i = 0; i < text.length; i += 1) {
    const c = text[i];
    if ('<(['.includes(c)) depth += 1;
    else if ('>)]'.includes(c)) depth -= 1;
    else if (c === ',' && depth === 0) { out.push(text.slice(start, i)); start = i + 1; }
  }
  out.push(text.slice(start));
  return out;
}
const schema = new Map();
for (const file of ['bend2/selfhost/backend_ir.bend', 'bend2/selfhost/ast.bend']) {
  let type = null;
  for (const line of readFileSync(join(root, file), 'utf8').split('\n')) {
    const t = /^type (\w+)(?:<[^>]*>)? is (?:Data|Type):/.exec(line);
    if (t) { type = t[1]; continue; }
    const c = /^  (\w+)\{([^}]*)\}$/.exec(line);
    if (!c || !type) continue;
    const fields = [];
    if (c[2].trim()) {
      for (const part of splitTop(c[2])) {
        if (!part.includes(':')) { fields.length = 0; break; }
        const at = part.indexOf(':');
        fields.push([part.slice(0, at).trim(), part.slice(at + 1).trim()]);
      }
    }
    schema.set(c[1], fields);
  }
}
const unknown = new Set();
function value(v, ty = null) {
  if (Array.isArray(v)) return '[' + v.map(x => value(x)).join(', ') + ']';
  if (v === null) return 'None{}';
  if (typeof v === 'boolean') return v ? 'True{}' : 'False{}';
  if (typeof v === 'number') return String(v) + (ty === 'Nat' ? 'n' : '');
  if (typeof v === 'string') return JSON.stringify(v);
  if (typeof v !== 'object') throw Error('bad BIR value ' + String(v));
  const tag = v.$;
  if (tag === 'Nil') return '[]';
  if (tag === 'Con') {
    const out = [];
    let cur = v;
    while (cur && cur.$ === 'Con') { out.push(value(cur.head)); cur = cur.tail; }
    if (!cur || cur.$ !== 'Nil') throw Error('malformed BIR list');
    return '[' + out.join(', ') + ']';
  }
  if (tag === 'None') return 'None{}';
  if (tag === 'Some') return 'Some{' + value(v.value) + '}';
  if (tag === 'True' || tag === 'False') return tag + '{}';
  if (typeof tag !== 'string') throw Error('unknown BIR tag ' + String(tag));
  const birPrefix = '../bend2/selfhost/backend_ir.';
  const astPrefix = '../bend2/selfhost/ast.';
  if (tag.startsWith(astPrefix)) {
    if (tag !== '../bend2/selfhost/ast.SpanOf') throw Error('unsupported Ast tag ' + tag);
    return 'Ast.SpanOf{' + schema.get('SpanOf').map(([k, t]) => value(v[k], t)).join(', ') + '}';
  }
  if (!tag.startsWith(birPrefix)) throw Error('non-canonical nominal tag ' + tag);
  const type = tag.slice(birPrefix.length);
  if (!schema.has(type)) throw Error('unknown BIR constructor ' + tag);
  const fields = schema.get(type);
  const keys = Object.keys(v).filter(k => k !== '$').sort();
  const expected = fields.map(([k]) => k).sort();
  if (keys.length !== expected.length || keys.some((k, i) => k !== expected[i]))
    throw Error('BIR fields mismatch for ' + type + ': observed ' + JSON.stringify(keys) + ', expected ' + JSON.stringify(expected));
  return 'BIR.' + type + '{' + fields.map(([k, t]) => value(v[k], t)).join(', ') + '}';
}

const sha = bytes => createHash('sha256').update(bytes).digest('hex');
const extraMap = new Map(extra.map(a => { const at = a.indexOf('='); return [a.slice(0, at), a.slice(at + 1)]; }));
const birBytes = readFileSync(birPath), bir = JSON.parse(birBytes.toString('utf8'));
const sourceBytes = readFileSync(sourcesPath), sources = JSON.parse(sourceBytes.toString('utf8'));
if (!Array.isArray(sources)) throw Error('sources bundle must be an array');
for (const row of sources) {
  const keys = Object.keys(row).sort();
  if (keys.length !== 2 || keys[0] !== 'path' || keys[1] !== 'source'
      || typeof row.path !== 'string' || typeof row.source !== 'string')
    throw Error('source bundle entry must be exactly {path, source} strings');
}
const runtimeBytes = readFileSync(runtimePath), runtime = runtimeBytes.toString('utf8');
const fileList = sources.map(s => 'BIR.SourceFile{' + value(s.path) + ', ' + value(s.source) + '}').join(',\n   ');
const text = `import Base
import ../bend2/selfhost/backend_ir.bend as BIR
import ../bend2/selfhost/ast.bend as Ast

# Generated diagnostic transport from a canonical checked source. Not committed.
def program() -> BIR.Program:
  ${value(bir)}

def runtime() -> String:
  ${value(runtime)}

def files() -> List<&2, BIR.SourceFile>:
  [${fileList}]
`;
writeFileSync(outPath, text);
const outBytes = readFileSync(outPath);
const result = {outPath, bytes: outBytes.length, sources: sources.length,
  birSha256: sha(birBytes), sourcesSha256: sha(sourceBytes), runtimeSha256: sha(runtimeBytes), outputSha256: sha(outBytes),
  sourceSha256: extraMap.has('--source') ? sha(readFileSync(extraMap.get('--source'))) : null,
  checkedSha256: extraMap.has('--checked') ? sha(readFileSync(extraMap.get('--checked'))) : null,
  componentSha256: extraMap.has('--component') ? sha(readFileSync(extraMap.get('--component'))) : null,
  unknownConstructors: []};
console.log(JSON.stringify(result));
