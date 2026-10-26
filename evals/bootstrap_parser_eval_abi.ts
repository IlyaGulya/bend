import * as B from '../bend2/bend.ts';
import {js_lib} from '../bend2/comp.ts';
import {createHash} from 'node:crypto';
import {writeFileSync} from 'node:fs';
import {resolve} from 'node:path';

let compiled: Promise<{
  lexer: {tokens(source: string): any}; artifactPath: string;
  artifactSha256: string; sourcePath: string; sourceSha256: string;
}> | undefined;

/** Observation seam only: compile and execute the current, natively checked
 * Bend lexer. Compiled parser artifacts execute their own unchanged lexer. */
export function compiledLexerABI() {
  return compiled ??= (async () => {
    const sourcePath = resolve('bend2/selfhost/lexer.bend');
    const sourceSha256 = createHash('sha256')
      .update(new Uint8Array(await Bun.file(sourcePath).arrayBuffer())).digest('hex');
    const native = B.book_nil();
    await B.book_load(native, sourcePath, 'lexer', new Map());
    B.book_valid(native);
    const source = js_lib(native, true, {
      roots: ['lexer:tokens'], exports: ['lexer:tokens'], releaseChecked: true,
    });
    const artifactSha256 = createHash('sha256').update(source).digest('hex');
    const artifactPath = resolve('checkpoints/bootstrap-lexer-token-producer-release237-' + artifactSha256 + '.js');
    if (await Bun.file(artifactPath).exists()) {
      if (await Bun.file(artifactPath).text() !== source)
        throw Error('Content-addressed lexer artifact differs from actual native emission');
    } else {
      writeFileSync(artifactPath, source, {flag: 'wx'});
    }
    const module = await import('data:text/javascript;base64,' + Buffer.from(source).toString('base64'));
    // A library exports each def by its internal book name; an imported
    // module's name keeps the namespace separator (`lexer:tokens`).
    return {lexer: {tokens: module.default['lexer:tokens']}, artifactPath,
      artifactSha256, sourcePath, sourceSha256};
  })();
}

export function lexerConstructorKey(hostKey: string, namespace = 'lexer'): string {
  if (!hostKey.startsWith('lexer.')) throw Error('Invalid current lexer constructor key');
  return namespace + ':' + hostKey.slice('lexer.'.length);
}

export async function installCompiledLexerABI(book: B.Book,
  prepared?: {source: string; tokens: any[]}) {
  const {lexer, ...proof} = await compiledLexerABI();
  function ctor(term: B.HTerm) {
    const value = B.term_wnf(book, term);
    const head = value.$ === 'Lit' ? B.lit_step(value) : value;
    if (head.$ !== 'Ctr') throw Error('Invalid lexer input ABI constructor');
    return head;
  }
  function text(term: B.HTerm) {
    let out = '';
    for (;;) {
      const value = B.term_wnf(book, term);
      if (value.$ === 'Lit' && value.k === 'String') return out + value.v;
      const item = ctor(value);
      if (item.k === 'SNil') return out;
      if (item.k !== 'SCon') throw Error('Invalid lexer input String');
      const character = ctor(item.x[0]);
      if (character.k !== 'Chr' || character.x.length !== 1)
        throw Error('Invalid lexer input character');
      const code = B.u32_from_term(B.term_lower(B.term_snf(book, character.x[0])));
      if (code === null) throw Error('Invalid lexer input character Word');
      out += String.fromCodePoint(code);
      term = item.x[1];
    }
  }
  function nat(value: number): B.HTerm {
    if (!Number.isSafeInteger(value) || value < 0)
      throw Error('Invalid current lexer ABI Nat');
    return B.Lit('Nat', value);
  }
  const tokenKeys = Object.keys(book.tlds).filter(key => key === 'lexer:tokens' || key.endsWith('/lexer:tokens'));
  if (tokenKeys.length !== 1) throw Error('Expected one authenticated lexer tokens provider');
  const namespace = tokenKeys[0]!.slice(0, -':tokens'.length);
  const definition = book.tlds[tokenKeys[0]!];
  if (definition?.$ !== 'Def') throw Error('Missing current lexer tokens definition');
  definition.v = B.Lam('source', 0, source => {
    const input = text(source);
    let tokens: any[];
    if (prepared && input === prepared.source) tokens = prepared.tokens;
    else {
      let native = lexer.tokens(input);
      tokens = [];
      while (native.$ === 'Con') { tokens.push(native.head); native = native.tail; }
      if (native.$ !== 'Nil') throw Error('Invalid compiled lexer token list');
    }
    let tail: B.HTerm = B.Ctr('Nil', []);
    for (let i = tokens.length - 1; i >= 0; i--) {
      const t = tokens[i];
      const token = B.Ctr(namespace + ':TokenInfo', [B.Ctr(lexerConstructorKey(t.kind.$, namespace), []),
        B.Lit('String', t.text), nat(t.beg), nat(t.end), nat(t.line), nat(t.col)]);
      tail = B.Ctr('Con', [token, tail]);
    }
    return tail;
  });
  return {...proof, implementation: 'Current native-validated Bend Lexer.tokens; exact compact String/Token/Nat ABI',
    preparedInEstablishedTokenWorker: prepared !== undefined};
}

/** FeedbackComplete carries a typed FeedbackValue, not ParseResult directly. */
export function feedbackParserResult(book: B.Book, run: B.HTerm): B.HTerm {
  function ctor(term: B.HTerm) {
    const value = B.term_wnf(book, term);
    if (value.$ !== 'Ctr') throw Error('Invalid feedback result constructor');
    return value;
  }
  const tag = (key: string) => B.name_key(key).split('.').at(-1)!;
  const complete = ctor(run);
  if (tag(complete.k) !== 'FeedbackComplete') throw Error('Explicit fuel result ' + complete.k);
  const value = ctor(complete.x[0]!);
  if (!/^Value_\d+$/.test(tag(value.k)) || value.x.length !== 1)
    throw Error('Invalid parser FeedbackValue ' + value.k);
  const result = ctor(value.x[0]!);
  if (!['ParseSuccess', 'ParseFailure'].includes(tag(result.k)))
    throw Error('Invalid parser feedback payload ' + result.k);
  return result;
}
