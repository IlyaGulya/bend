#!/usr/bin/env bun
/** Source-preserving CheckerCore SCC lowering. This generates source only; it
 * never validates, compiles, emits JS, or modifies the canonical/frozen inputs.
 * Raw Body/signature parsing follows parser_full_graph.ts; source call splicing
 * follows parser_feedback_generate.ts rather than reprinting algorithm bodies.
 */
import {createHash, randomUUID} from 'node:crypto';
import {existsSync, readFileSync, writeFileSync, rmSync} from 'node:fs';
import {dirname, posix, resolve} from 'node:path';
import * as B from '../bend2/bend.ts';
import type {ParserParameter} from './parser_full_graph.ts';

const paths = {
  canonical: 'bend2/selfhost/checker.bend',
  owned: 'checkpoints/checker_core_owned_v1.bend',
  dependency: 'checkpoints/checker-core-dependency.json',
  frozenSlice: 'checkpoints/checker_core_slice.bend',
  frozenDriver: 'checkpoints/checker_core_driver.bend',
  frozenCorpus: 'checkpoints/bootstrap-real-source-corpus.json',
  output: 'checkpoints/checker_core_lowered_v1.bend',
  component: 'checkpoints/checker_core_lowered_component_v1.bend',
  driver: 'checkpoints/checker_core_lowered_driver_v1.bend',
  manifest: 'checkpoints/checker-core-scc-lowered-v1.json',
} as const;
const sha = (text: string) => createHash('sha256').update(text).digest('hex');
function writeChanged(path: string, text: string): void {
  if (!existsSync(path) || readFileSync(path, 'utf8') !== text) writeFileSync(path, text);
}
const inputPaths = [paths.canonical, paths.owned, paths.dependency, paths.frozenSlice, paths.frozenDriver, paths.frozenCorpus];
const inputs = new Map(inputPaths.map(path => [path, readFileSync(path, 'utf8')]));
let source = inputs.get(paths.owned)!;

/** Keep coordinates intact, including comment-looking text inside strings. */
function mask(text: string): string {
  let result = '', quote = '', escaped = false, comment = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i]!;
    if (comment) { if (c === '\n') {comment = false; result += c;} else result += ' '; }
    else if (quote) {
      result += c === '\n' ? '\n' : ' ';
      if (escaped) escaped = false;
      else if (c === '\\') escaped = true;
      else if (c === quote) quote = '';
    } else if (c === '"' || c === "'") {quote = c; result += ' ';}
    else if (c === '#' || text.startsWith('//', i)) {comment = true; result += ' ';}
    else result += c;
  }
  if (quote) throw Error('Unterminated string in source');
  return result;
}
const masked = mask(source);
const starts = [...masked.matchAll(/^def ([A-Za-z_][A-Za-z_0-9]*)\(/gm)];
const names = new Set(starts.map(match => match[1]!));
if (names.size !== starts.length || starts.length !== 416) throw Error('CheckerCore must have exactly 416 unique definitions');
if (/^(type|law) /m.test(masked.slice(starts[0]!.index))) throw Error('Interleaved declarations need explicit lowering support');
const header = source.slice(0, starts[0]!.index);
const dependency = JSON.parse(inputs.get(paths.dependency)!);
const included = new Set<string>(dependency.included.map((entry: {name: string}) => entry.name));
if (included.size !== names.size || [...names].some(name => !included.has(name))) throw Error('Exact CheckerCore closure membership drift');
const canonical = inputs.get(paths.canonical)!;
const canonicalStarts = [...mask(canonical).matchAll(/^def ([A-Za-z_][A-Za-z_0-9]*)\(/gm)];
const canonicalBlocks = new Map(canonicalStarts.map((match, i) => [match[1]!, canonical.slice(match.index, canonicalStarts[i + 1]?.index ?? canonical.length)]));

function split(text: string): string[] {
  if (!text.trim()) return [];
  const clean = mask(text), stack: string[] = [], parts: string[] = [];
  let begin = 0;
  for (let i = 0; i < clean.length; i++) {
    const c = clean[i]!;
    if (clean.startsWith('<>', i) || clean.startsWith('=>', i) || clean.startsWith('->', i)) {i++; continue;}
    if ('([{<'.includes(c)) stack.push(c);
    else if (')}]>'.includes(c)) {
      if (stack.pop() !== '([{<'[')]}>'.indexOf(c)]) throw Error('Unbalanced signature: ' + text);
    } else if (c === ',' && !stack.length) {parts.push(text.slice(begin, i).trim()); begin = i + 1;}
  }
  if (stack.length) throw Error('Unbalanced signature: ' + text);
  parts.push(text.slice(begin).trim());
  return parts;
}
type Call = {callee: string; begin: number; open: number; close: number; arity: number};
type Definition = {name: string; order: number; begin: number; end: number; bodyBegin: number;
  signature: string; parameters: ParserParameter[]; fields: string[]; result: string;
  body: string; originalBody: string; block: string; calls: Call[]; direct: string[]; tailCalls: Set<number>};

// Load only the original imports/datatypes. In particular, do not flatten any
// CheckerCore function or run the native checker as part of source generation.
const book = B.book_nil();
const temporary = resolve(dirname(paths.owned), '.checker_core_scc_datatypes_' + randomUUID() + '.bend');
try {writeFileSync(temporary, header); await B.book_load(book, temporary, '', new Map());}
finally {rmSync(temporary, {force: true});}
const aliases: Record<string, string> = Object.create(null);
for (const match of header.matchAll(/^import (\S+) as ([A-Za-z_]\w*)$/gm)) aliases[match[2]!] = posix.normalize(match[1]!).replace(/\.bend$/, '');
const line = (offset: number) => source.slice(0, offset).split('\n').length;
const constructorApplications=new Map<number,{name:string;open:number;close:number;arity:number}>();
const definitions: Definition[] = starts.map((match, order) => {
  const name = match[1]!, begin = match.index!, end = starts[order + 1]?.index ?? source.length;
  const block = source.slice(begin, end);
  if (canonicalBlocks.get(name) !== block) throw Error('Owned definition is not the exact current canonical block: ' + name);
  const signatureEnd = source.indexOf('\n', begin);
  const signature = source.slice(begin, signatureEnd);
  const signatureMatch = /^def [A-Za-z_]\w*\((.*)\) -> (.*):$/.exec(signature);
  if (!signatureMatch) throw Error('Unsupported one-line signature: ' + name);
  const p: B.Parse = {book, dir: resolve(dirname(paths.owned)) + '/', str: source, pos: begin,
    stk: [], frs: 0, ns: '', al: aliases};
  if (!B.parse_word(p, 'def') || B.parse_name(p) !== name) throw Error('Definition parse drift: ' + name);
  B.parse_eat(p, '(');
  const parameters = B.parse_tele(p, ')');
  B.parse_eat(p, '->');
  const resultAst = B.parse_term(p);
  B.parse_eat(p, ':');
  const bodyAst = B.parse_body(p);
  const fields = split(signatureMatch[1]!);
  if (fields.length !== parameters.length) throw Error('Parameter telescope/source drift: ' + name);
  for (const [i, parameter] of parameters.entries()) {
    const spelling = /^([+-]?)([A-Za-z_]\w*)\s*:\s*(.+)$/.exec(fields[i]!);
    if (!spelling || spelling[2] !== parameter[1] || spelling[1] !== B.quant_show(parameter[0])) throw Error('Unsupported parameter spelling: ' + name);
  }
  function binder(key: string) {if (names.has(key)) throw Error('Local definition shadowed by binder: ' + name + '/' + key);}
  parameters.forEach(parameter => binder(parameter[1]));
  function pattern(node: B.Patt): void {
    if (node.$ === 'PVar') binder(node.k);
    else node.x.forEach(pattern);
  }
  // Source calls are identified by Ref, not spelling: local Var nodes, lambda
  // binders, pattern binders, and strings/comments cannot become graph edges.
  const calls = new Map<number, Call>();
  const tailCalls=new Set<number>();
  function reference(head: B.LTerm, arity: number) {
    if (head.$ !== 'Ref' || !names.has(head.k)) return;
    if (!head.s || head.s.file.str !== source) throw Error('Missing original call span: ' + name + '/' + head.k);
    const start = head.s.beg;
    if (source.slice(start, start + head.k.length) !== head.k) throw Error('Call source drift: ' + name + '/' + head.k);
    let open = start + head.k.length;
    while (/\s/.test(masked[open] ?? '') && open < end) open++;
    if (masked[open] !== '(') throw Error('Unsupported non-call local reference: ' + name + '/' + head.k);
    let depth = 1, close = open + 1;
    while (close < end && depth) {if (masked[close] === '(') depth++; else if (masked[close] === ')') depth--; if (depth) close++;}
    if (depth) throw Error('Unclosed call: ' + name + '/' + head.k);
    const found = calls.get(start);
    if (found && found.arity !== arity) throw Error('Ambiguous local call AST: ' + name + '/' + head.k);
    calls.set(start, {callee: head.k, begin: start, open, close, arity});
  }
  function term(term: B.LTerm): void {
    if (term.$ === 'App') {
      const [head, args] = B.term_unapply(term);
      if(head.$==='Ref'&&book.ctrs[head.k]&&!names.has(head.k)&&head.s){
        const constructor=book.ctrs[head.k]!;
        if(args.length!==constructor.n)throw Error('Constructor application arity differs from native fields: '+name+'/'+head.k);
        const open=source.indexOf('(',head.s.beg);let depth=1,close=open+1;
        while(close<end&&depth){if(masked[close]==='(')depth++;else if(masked[close]===')')depth--;if(depth)close++;}
        if(open<0||depth)throw Error('Constructor call span drift: '+name+'/'+head.k);
        constructorApplications.set(open,{name:head.k,open,close,arity:args.length});
      }
      if (head.$ === 'Ref' && names.has(head.k)) reference(head, args.length);
      else visitTermHead(head);
      args.forEach(visitTermHead);
      return;
    }
    if (term.$ === 'Ref') {reference(term, 0); return;}
    if (term.$ === 'Var') {if (names.has(term.k)) throw Error('Shadowed local call/reference: ' + name + '/' + term.k); return;}
    if (term.$ === 'Lam' || term.$ === 'All' || term.$ === 'Sub') binder(term.k);
    if (term.$ === 'Let') term.k.forEach(binder);
    for (const [key, child] of Object.entries(term)) {
      if (key === 's') continue;
      if (Array.isArray(child)) for (const value of child) {if (value && typeof value === 'object' && '$' in value) visitTermHead(value as B.LTerm);}
      else if (child && typeof child === 'object' && '$' in child) visitTermHead(child as B.LTerm);
    }
  }
  function visitTermHead(value: B.LTerm | B.Patt): void {
    if (value.$ === 'PVar' || value.$ === 'PCtr') pattern(value);
    else term(value);
  }
  function extend(patterns: B.Patt[], input: B.Env): B.Env {
    let env = input;
    function bind(node: B.Patt): void {
      if (node.$ === 'PVar') env = B.list_set(env, node.i, B.Var(node.k, node.i));
      else node.x.forEach(bind);
    }
    patterns.forEach(bind);
    return env;
  }
  function scopedTerm(value: B.LTerm, env: B.Env): void {
    term(B.term_lower(B.term_higher(value, env), p.frs));
  }
  function body(node: B.Body, env: B.Env): void {
    switch (node.$) {
      case 'Local': node.v.forEach(value => scopedTerm(value, env)); node.k.forEach(pattern); body(node.f, extend(node.k, env)); break;
      case 'Match': node.e.forEach(value => scopedTerm(value, env)); node.r.forEach(row => {row.p.forEach(pattern); body(row.f, extend(row.p, env));}); break;
      default: {
        const value=B.term_lower(B.term_higher(node,env),p.frs),[head]=B.term_unapply(value);
        if(head.$==='Ref'&&head.s&&names.has(head.k))tailCalls.add(head.s.beg);
        scopedTerm(node, env); break;
      }
    }
  }
  // Signature-local function dependencies need a separate declaration-order
  // lowering; the current first-order closure has none. Reject instead of
  // silently omitting any new dependency introduced by future source changes.
  let parameterEnv: B.Env = null;
  for (const parameter of parameters) {
    scopedTerm(parameter[3], parameterEnv);
    parameterEnv = B.list_set(parameterEnv, parameter[2], B.Var(parameter[1], parameter[2]));
  }
  scopedTerm(resultAst, parameterEnv);
  if (calls.size) throw Error('Unsupported local function reference in signature: ' + name);
  body(bodyAst, parameterEnv);
  const bodyBegin = signatureEnd + 1;
  // Independently enforce the audit's bare-name first-order constraint, including
  // syntax that a future AST variant might otherwise silently skip.
  for (const token of masked.slice(bodyBegin, end).matchAll(/\b[A-Za-z_]\w*\b/g)) {
    const offset = bodyBegin + token.index!;
    if (names.has(token[0]) && masked[offset - 1] !== '.' && !calls.has(offset)) throw Error('Unaccounted local identifier: ' + name + '/' + token[0]);
  }
  return {name, order, begin, end, bodyBegin, signature, parameters, fields, result: signatureMatch[2]!,
    body: source.slice(bodyBegin, end), originalBody: source.slice(bodyBegin,end), block, calls: [...calls.values()].sort((a, b) => a.begin - b.begin), direct: [...new Set([...calls.values()].map(call => call.callee))],tailCalls};
});
// Constructor parentheses are source sugar, not native function definitions.
// Normalize only AST Ref applications authenticated by the constructor table.
for(const call of [...constructorApplications.values()].sort((a,b)=>b.open-a.open)){
  source=source.slice(0,call.open)+'{'+source.slice(call.open+1,call.close)+'}'+source.slice(call.close+1);
}
for(const definition of definitions){
  definition.body=source.slice(definition.bodyBegin,definition.end);
  definition.block=source.slice(definition.begin,definition.end);
}
const byName = new Map(definitions.map(definition => [definition.name, definition]));
for (const definition of definitions) for (const call of definition.calls) {
  if (call.arity > byName.get(call.callee)!.parameters.length) throw Error('Unsupported overapplied local call: ' + definition.name + '/' + call.callee);
}

function tarjan(order: string[], edges: ReadonlyMap<string, readonly string[]>): string[][] {
  const ids = new Map<string, number>(), lows = new Map<string, number>(), active = new Set<string>(), stack: string[] = [], result: string[][] = [];
  let index = 0;
  function visit(name: string): void {
    ids.set(name, index); lows.set(name, index++); stack.push(name); active.add(name);
    for (const next of edges.get(name)!) {
      if (!ids.has(next)) {visit(next); lows.set(name, Math.min(lows.get(name)!, lows.get(next)!));}
      else if (active.has(next)) lows.set(name, Math.min(lows.get(name)!, ids.get(next)!));
    }
    if (lows.get(name) === ids.get(name)) {
      const component: string[] = []; let member: string;
      do {member = stack.pop()!; active.delete(member); component.push(member);} while (member !== name);
      result.push(component);
    }
  }
  order.forEach(name => {if (!ids.has(name)) visit(name);});
  return result;
}
const edges = new Map(definitions.map(definition => [definition.name, definition.direct]));
const components = tarjan([...names], edges).map(members => members.sort((a, b) => byName.get(a)!.order - byName.get(b)!.order));
const componentOf = new Map(components.flatMap((members, id) => members.map(name => [name, id] as const)));
const reachable = new Set<string>(), pending = ['check_modules'];
while (pending.length) {const name = pending.pop()!; if (!reachable.has(name)) {reachable.add(name); pending.push(...edges.get(name)!);}}
if (reachable.size !== definitions.length) throw Error('check_modules no longer reaches the complete 416-definition closure');
// Tarjan emits dependencies first; explicitly enforce that property, rather than
// depending on a persisted ordering audit or an accidental source order.
for (const definition of definitions) for (const dependency of definition.direct) {
  if (componentOf.get(dependency)! > componentOf.get(definition.name)!) throw Error('Component DAG order drift');
}
const reserved = new Set([...masked.matchAll(/\b[A-Za-z_]\w*\b/g)].map(match => match[0]));
function reserve(name: string): string {if (reserved.has(name)) throw Error('Generated name collision: ' + name); reserved.add(name); return name;}
const loweredEdges = new Map<string, string[]>(), emittedOrder: string[] = [], chunks = [header], componentRows: object[] = [], bodyRows: object[] = [];
let rewrittenCalls = 0;
function emit(name: string, text: string, dependencies: string[]) {emittedOrder.push(name); loweredEdges.set(name, [...new Set(dependencies)]); chunks.push(text);}
for (const [id, members] of components.entries()) {
  if (members.length === 1) {
    const definition = byName.get(members[0]!)!;
    emit(definition.name, definition.block, definition.direct);
    bodyRows.push({name: definition.name, component: id + 1, originalBody: {path: paths.owned, begin: definition.bodyBegin, end: definition.end, sha256: sha(definition.originalBody)}, bodyUnchanged: definition.body===definition.originalBody, nativeConstructorSyntaxNormalized:definition.body!==definition.originalBody, rewrittenCalls: []});
    componentRows.push({id: id + 1, members, lowered: false});
    continue;
  }
  // Fuse a single acyclic helper phase when its saturated tail arguments are
  // identical bound names. No evaluation, parameter substitution or new state.
  if(members.length===2){
    const fusion=members.map(name=>{
      const root=byName.get(name)!,helper=byName.get(members.find(member=>member!==name)!)!;
      const calls=root.calls.filter(call=>call.callee===helper.name);
      if(helper.direct.includes(helper.name)||!calls.length||calls.some(call=>!root.tailCalls.has(call.begin)||call.arity!==helper.parameters.length||split(source.slice(call.open+1,call.close)).some((argument,index)=>argument!==helper.parameters[index]![1])))return;
      return {root,helper,calls};
    }).find(Boolean);
    if(fusion){
      const {root,helper,calls}=fusion,edits=calls.map(call=>{
        const begin=source.lastIndexOf('\n',call.begin)+1,end=source.indexOf('\n',call.close);
        const prefix=source.slice(begin,call.begin),suffix=source.slice(call.close+1,end<0?root.end:end);
        if(suffix.trim()||!/^ *$|^ *case .*: *$/.test(prefix))throw Error('Tail helper fusion line shape drift: '+root.name);
        const indent=/^ */.exec(prefix)![0].length+(prefix.trim()?2:0);
        const body=helper.body.trimEnd().split('\n').map(line=>line.trim()?' '.repeat(indent)+line.slice(2):line).join('\n');
        return {begin,end:end<0?root.end:end,after:(prefix.trim()?prefix.trimEnd()+'\n':'')+body};
      }).sort((a,b)=>b.begin-a.begin);
      let body=root.body;
      for(const edit of edits)body=body.slice(0,edit.begin-root.bodyBegin)+edit.after+body.slice(edit.end-root.bodyBegin);
      // A nested match cannot inspect an outer parameter after the first match.
      // For scalar, direct-reply clauses, form the ordered pattern product.
      const scalarMatch=(text:string)=>{
        const lines=text.trimEnd().split('\n').filter(line=>line.trim()&&!line.trimStart().startsWith('#'));
        const head=/^  match ([A-Za-z_]\w*):$/.exec(lines[0]??'');
        if(!head)return;
        const rows=[];
        for(const line of lines.slice(1)){
          if(!line.startsWith('    case '))return;
          const colon=mask(line).indexOf(':');
          if(colon<0)return;
          rows.push({pattern:line.slice(9,colon),reply:line.slice(colon+1).trim()});
        }
        return {parameter:head[1]!,rows};
      };
      const outer=scalarMatch(root.body),inner=scalarMatch(helper.body);
      let loopName:string|undefined,permutation:number[]|undefined;
      if(outer&&inner&&outer.parameter!==inner.parameter&&root.parameters.some(parameter=>parameter[1]===inner.parameter)){
        const selectedCalls=new Set(calls.map(call=>source.slice(call.begin,call.close+1)));
        const rows=outer.rows.flatMap(row=>selectedCalls.has(row.reply)?inner.rows.map(child=>'    case '+row.pattern+' '+child.pattern+': '+child.reply):['    case '+row.pattern+' _: '+row.reply]);
        body='  match '+outer.parameter+' '+inner.parameter+':\n'+rows.join('\n')+'\n\n';
        loopName=reserve('checker_scc_fused_'+root.name);
        const first=root.parameters.findIndex(parameter=>parameter[1]===outer.parameter),second=root.parameters.findIndex(parameter=>parameter[1]===inner.parameter);
        permutation=[first,second,...root.parameters.map((_,index)=>index).filter(index=>index!==first&&index!==second)];
        const clean=mask(body),rewrites=[];
        for(const match of clean.matchAll(new RegExp('\\b'+root.name+'\\s*\\(','g'))){
          const begin=match.index!,open=clean.indexOf('(',begin);let depth=1,close=open+1;
          for(;close<clean.length&&depth;close++){if(clean[close]==='(')depth++;else if(clean[close]===')')depth--;}
          const arguments_=split(body.slice(open+1,close-1));
          if(depth||arguments_.length!==root.parameters.length)throw Error('Fused recursive call arity drift: '+root.name);
          rewrites.push({begin,end:close,after:loopName+'('+permutation.map(index=>arguments_[index]).join(', ')+')'});
        }
        for(const rewrite of rewrites.reverse())body=body.slice(0,rewrite.begin)+rewrite.after+body.slice(rewrite.end);
      }
      const dependencies=[...new Set([...root.direct.filter(name=>name!==helper.name),...helper.direct])];
      if(loopName&&permutation){
        emit(loopName,'def '+loopName+'('+permutation.map(index=>root.fields[index]).join(', ')+') -> '+root.result+':\n'+body,dependencies.map(name=>name===root.name?loopName!:name));
        emit(root.name,root.signature+'\n  '+loopName+'('+permutation.map(index=>root.parameters[index]![1]).join(', ')+')\n\n',[loopName]);
      }else emit(root.name,root.signature+'\n'+body,dependencies);
      emit(helper.name,helper.block,helper.direct);
      rewrittenCalls+=calls.length;
      componentRows.push({id:id+1,members,lowered:true,method:'identity-argument saturated tail-helper fusion',root:root.name,helper:helper.name,loopName,permutation,fusedCalls:calls.map(call=>({begin:call.begin,end:call.close+1}))});
      bodyRows.push({name:root.name,component:id+1,originalBody:{path:paths.owned,begin:root.bodyBegin,end:root.end,sha256:sha(root.originalBody)},rewrittenBodySha256:sha(body),tailHelperFusion:true});
      bodyRows.push({name:helper.name,component:id+1,bodyUnchanged:helper.body===helper.originalBody,nativeConstructorSyntaxNormalized:helper.body!==helper.originalBody});
      continue;
    }
  }
  const inputType = reserve('CheckerSccInput' + (id + 1)), resultName = reserve('checker_scc_result_' + (id + 1)), dispatcher = reserve('checker_scc_run_' + (id + 1));
  const constructors = new Map(members.map(name => [name, reserve('CheckerSccCall_' + name)]));
  chunks.push('type ' + inputType + ' is Data:\n' + members.map(name => '  ' + constructors.get(name) + '{' + byName.get(name)!.fields.join(', ') + '}').join('\n') + '\n\n');
  emit(resultName, 'def ' + resultName + '(request: ' + inputType + ') -> Type:\n  match request:\n' + members.map(name => {
    const definition = byName.get(name)!;
    return '    case ' + constructors.get(name) + '{' + definition.parameters.map(parameter => B.quant_show(parameter[0]) + parameter[1]).join(', ') + '}: ' + definition.result;
  }).join('\n') + '\n\n', []);
  const runDependencies = [resultName];
  const branches = members.map(name => {
    const definition = byName.get(name)!;
    const selected = definition.calls.filter(call => componentOf.get(call.callee) === id);
    const edits: {begin: number; end: number; before: string; after: string}[] = [];
    for (const call of selected) {
      // Two disjoint edits per call retain every argument byte, including nested
      // calls/comments. This is the call-rendering equivalent of Run(Ctr{args}).
      const missing = byName.get(call.callee)!.parameters.slice(call.arity).map((parameter, index) => ({
        name: reserve('checker_scc_arg_' + call.begin + '_' + index), quantity: parameter[0],
      }));
      if (missing.some(parameter => parameter.quantity.$ === 'None')) throw Error('Erased partial-call binder needs an explicit source representation: ' + name + '/' + call.callee);
      const prefix = missing.length ? '(' + missing.map(parameter => B.quant_show(parameter.quantity) + parameter.name + ' => ').join('') : '';
      const suffix = missing.length ? (call.arity ? ', ' : '') + missing.map(parameter => parameter.name).join(', ') + '}))' : '})';
      edits.push({begin: call.begin, end: call.open + 1, before: source.slice(call.begin, call.open + 1), after: prefix + dispatcher + '(' + constructors.get(call.callee) + '{'});
      edits.push({begin: call.close, end: call.close + 1, before: ')', after: suffix});
    }
    edits.sort((a, b) => a.begin - b.begin);
    let cursor = definition.bodyBegin, rewritten = '';
    for (const edit of edits) {
      if (edit.begin < cursor || source.slice(edit.begin, edit.end) !== edit.before) throw Error('Overlapping/drifted call edits: ' + name);
      rewritten += source.slice(cursor, edit.begin) + edit.after; cursor = edit.end;
    }
    rewritten += source.slice(cursor, definition.end);
    // Inversion is an emission invariant, not a substitute for native/runtime
    // validation: it proves that arguments and every non-call body byte survived.
    let inverse = '', originalCursor = definition.bodyBegin, rewrittenCursor = 0;
    for (const edit of edits) {
      const kept = edit.begin - originalCursor;
      inverse += rewritten.slice(rewrittenCursor, rewrittenCursor + kept) + edit.before;
      rewrittenCursor += kept + edit.after.length; originalCursor = edit.end;
    }
    inverse += rewritten.slice(rewrittenCursor);
    if (inverse !== definition.body) throw Error('Call lowering inverse differs: ' + name);
    rewrittenCalls += selected.length;
    runDependencies.push(...definition.direct.map(target => componentOf.get(target) === id ? dispatcher : target));
    bodyRows.push({name, component: id + 1, constructor: constructors.get(name), originalSignature: definition.signature,
      parameters: definition.parameters.map((parameter, i) => ({name: parameter[1], quantity: parameter[0].$, exactFieldSource: definition.fields[i]})), exactReturnType: definition.result,
      originalBody: {path: paths.owned, begin: definition.bodyBegin, end: definition.end, sha256: sha(definition.originalBody)}, normalizedOriginalBodySha256:sha(definition.body),
      rewrittenBodySha256: sha(rewritten), exactCallEditInverse: true,
      rewrittenCalls: selected.map(call => ({callee: call.callee, begin: call.begin, end: call.close + 1, line: line(call.begin), constructor: constructors.get(call.callee),
        suppliedArguments: call.arity, formalParameters: byName.get(call.callee)!.parameters.length,
        etaExpandedRemainingParameters: byName.get(call.callee)!.parameters.slice(call.arity).map(parameter => ({name: parameter[1], quantity: parameter[0].$}))})), sourceEdits: edits});
    return '    case ' + constructors.get(name) + '{' + definition.parameters.map(parameter => B.quant_show(parameter[0]) + parameter[1]).join(', ') + '}:\n'
      + rewritten.split('\n').map(text => text ? '    ' + text : text).join('\n');
  });
  emit(dispatcher, 'def ' + dispatcher + '(request: ' + inputType + ') -> ' + resultName + '(request):\n  match request:\n' + branches.join('') + '\n', runDependencies);
  for (const name of members) {
    const definition = byName.get(name)!;
    emit(name, definition.signature + '\n  ' + dispatcher + '(' + constructors.get(name) + '{' + definition.parameters.map(parameter => parameter[1]).join(', ') + '})\n\n', [dispatcher]);
  }
  componentRows.push({id: id + 1, members, lowered: true, inputType, resultTypeFunction: resultName, dispatcher,
    constructors: Object.fromEntries(constructors), returnTypes: [...new Set(members.map(name => byName.get(name)!.result))],
    rewrittenCallCount: members.reduce((count, name) => count + byName.get(name)!.calls.filter(call => componentOf.get(call.callee) === id).length, 0)});
}
const residualMutual = tarjan(emittedOrder, loweredEdges).filter(members => members.length > 1);
const positions = new Map(emittedOrder.map((name, index) => [name, index]));
const forwardEdges = emittedOrder.flatMap(name => loweredEdges.get(name)!.filter(next => positions.get(next)! > positions.get(name)!).map(next => ({from: name, to: next})));
if (residualMutual.length || forwardEdges.length) throw Error('Lowered graph retains mutual SCCs or forward DAG references');
const output = chunks.join('');
const component = 'import ../bend2/selfhost/loaded_module.bend as Loader\nimport ./checker_core_lowered_v1.bend as CheckerCore\n\ndef check_expanded(modules: List<&2, Loader.LoadedModule>) -> CheckerCore.CheckResult:\n  CheckerCore.check_modules(modules, Nil{})\n';
const driverSource = inputs.get(paths.frozenDriver)!;
const driverAnchor = 'import ./checker_core_slice.bend as CheckerCore';
if (driverSource.split(driverAnchor).length !== 2) throw Error('Frozen driver import anchor drift');
const driver = driverSource.replace(driverAnchor, 'import ./checker_core_lowered_v1.bend as CheckerCore');
for (const [path, text] of inputs) if (readFileSync(path, 'utf8') !== text) throw Error('Input changed during generation: ' + path);
writeChanged(paths.output, output);
writeChanged(paths.component, component);
writeChanged(paths.driver, driver);
const manifest = {
  schema: 'checker-core-mechanical-dependent-scc-lowering-v1',
  method: 'Stage-0 raw signature/Body AST with binding-aware Ref call sites; authenticated constructor applications are normalized to native field braces without shifting coordinates. Fresh Tarjan and dependency-first SCC DAG; saturated identity-argument tail helpers may be fused, using ordered joint matches and private binder-ordered workers. Other SCCs use precise dependent result-type dispatchers without sum projections. Underapplications retain supplied argument positions through exact-quantity eta expansion, not semantic repair. Rejects local-name shadowing, noncall references, overapplications, erased partial-call binders, and signature-local function dependencies.',
  inputs: [...inputs].map(([path, text]) => ({path, sha256: sha(text), unchanged: true})),
  outputs: [{path: paths.output, sha256: sha(output)}, {path: paths.component, sha256: sha(component)}, {path: paths.driver, sha256: sha(driver)}],
  manifestPath: paths.manifest, originalDefinitionCount: definitions.length, originalRoot: 'check_modules',
  originalRootReachableMembers: definitions.filter(definition => reachable.has(definition.name)).map(definition => definition.name),
  originalMutualSccCount: components.filter(members => members.length > 1).length, rewrittenCallCount: rewrittenCalls,
  originalUnderapplications: definitions.flatMap(definition => definition.calls.filter(call => call.arity < byName.get(call.callee)!.parameters.length).map(call => ({
    caller: definition.name, callee: call.callee, path: paths.owned, begin: call.begin, end: call.close + 1, line: line(call.begin),
    suppliedArguments: call.arity, formalParameters: byName.get(call.callee)!.parameters.length,
    originalCall: inputs.get(paths.owned)!.slice(call.begin, call.close + 1),
    remainingFormals: byName.get(call.callee)!.parameters.slice(call.arity).map((parameter, index) => ({position: call.arity + index, name: parameter[1], quantity: parameter[0].$, exactSource: byName.get(call.callee)!.fields[call.arity + index]})),
    preservedSuppliedArgumentPositions: true, semanticRepairApplied: false,
    handling: componentOf.get(call.callee) === componentOf.get(definition.name) && components[componentOf.get(definition.name)!]!.length > 1 ? 'exact-quantity eta expansion around dispatcher request' : 'original call retained byte-identically',
  }))),
  generatedDefinitionCount: emittedOrder.length, residualMutualSccCount: residualMutual.length, forwardDagReferenceCount: forwardEdges.length,
  allOriginalApisPreserved: true, allOriginalParametersTypesQuantitiesPreserved: true,
  constructorSyntaxNormalizations:[...constructorApplications.values()],
  semanticEdits: 'Native constructor applications use field braces authenticated by the constructor table. Saturated identity-argument tail helpers may be fused, with ordered joint matches and private workers respecting binder order. Other SCC calls become dependent-result dispatcher requests; existing underapplications retain supplied argument positions through exact-quantity eta expansion. No missing inference argument is supplied.',
  unsafeAnnotationsAdded: 0, fuelLimitsAdded: 0, fakeFallbacksAdded: 0, exclusionsAdded: 0,
  nativeValidation: 'NOT RUN by source generator; parent must validate the entire generated closure and compiled semantics.',
  dependencyFirstComponents: componentRows, bodies: bodyRows,
  generatedCallGraph: emittedOrder.map(name => ({name, dependencies: loweredEdges.get(name)})),
};
writeChanged(paths.manifest, JSON.stringify(manifest, null, 2) + '\n');
console.log(JSON.stringify({source: paths.output, originalDefinitions: definitions.length, loweredMutualSccs: manifest.originalMutualSccCount, rewrittenCalls, residualMutualSccs: residualMutual.length, forwardDagReferences: forwardEdges.length, manifest: paths.manifest}));
