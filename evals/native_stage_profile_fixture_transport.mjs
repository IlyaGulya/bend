#!/usr/bin/env node
// Diagnostic transport only: render a canonical BIR.Program plus its real C
// source bundle as a Bend data module. No checker/renderer logic is duplicated.
import {readFileSync, writeFileSync} from 'node:fs';
import {dirname, join, resolve} from 'node:path';
import {fileURLToPath} from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const [birPath, sourcesPath, runtimePath, outPath] = process.argv.slice(2);
if (!birPath || !sourcesPath || !runtimePath || !outPath) throw Error('usage: bir.json sources.json runtime.c out.bend');

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
    if (fields.length) schema.set(c[1], fields);
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
  if (typeof tag !== 'string' || !tag.includes('.')) throw Error('unknown BIR tag ' + String(tag));
  const type = tag.slice(tag.lastIndexOf('.') + 1);
  if (type === 'SpanOf')
    return 'Ast.SpanOf{' + schema.get('SpanOf').map(([k, t]) => value(v[k], t)).join(', ') + '}';
  const fields = schema.get(type);
  if (!fields) { unknown.add(type); return 'BIR.' + type + '{}'; }
  return 'BIR.' + type + '{' + fields.map(([k, t]) => {
    if (!(k in v)) throw Error('missing ' + type + '.' + k);
    return value(v[k], t);
  }).join(', ') + '}';
}

const bir = JSON.parse(readFileSync(birPath, 'utf8'));
const sources = JSON.parse(readFileSync(sourcesPath, 'utf8'));
const runtime = readFileSync(runtimePath, 'utf8');
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
console.log(JSON.stringify({outPath, bytes: Buffer.byteLength(text), sources: sources.length,
  birSha256: '', unknownConstructors: [...unknown]}));
