import {expect,test} from 'bun:test';
import {readParserGraph} from './parser_full_graph.ts';
import {analyzeTokenProvenance} from './parser_full_token_provenance.ts';
const preamble='import Base\nimport ./lexer.bend as Lexer\n';
async function analyze(source:string){return analyzeTokenProvenance(await readParserGraph(preamble+source));}
test('identity preserves the input cursor',async()=>{
 const proof=await analyze('def identity(tokens: List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:\n  tokens\n');
 expect(proof.relationOf('identity',0,[])).toBe('Same');
});
test('a direct matched tail is a strict suffix',async()=>{
 const proof=await analyze('def tail(tokens: List<&2, Lexer.Token>) -> Maybe<&2, List<&2, Lexer.Token>>:\n  match tokens:\n    case head <> rest:\n      Some{rest}\n    case Nil{}:\n      None{}\n');
 expect(proof.relationOf('tail',0,[0],{path:[],constructor:'Some'})).toBe('StrictSuffix');
});
test('tuple storage and local projection preserve Same',async()=>{
 const proof=await analyze('def roundtrip(tokens: List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:\n  pair = { (True{}, tokens) : Bool & List<&2, Lexer.Token> }\n  match pair:\n    case (flag, cursor):\n      cursor\n');
 expect(proof.relationOf('roundtrip',0,[])).toBe('Same');
});
test('a strict tail survives tuple storage and projection',async()=>{
 const proof=await analyze('def stored_tail(tokens: List<&2, Lexer.Token>) -> Maybe<&2, List<&2, Lexer.Token>>:\n  match tokens:\n    case head <> rest:\n      pair = { (False{}, rest) : Bool & List<&2, Lexer.Token> }\n      match pair:\n        case (flag, cursor):\n          Some{cursor}\n    case Nil{}:\n      None{}\n');
 expect(proof.relationOf('stored_tail',0,[0],{path:[],constructor:'Some'})).toBe('StrictSuffix');
});
test('function summaries compose cursor identity',async()=>{
 const proof=await analyze('def relay(tokens: List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:\n  identity(tokens)\ndef identity(cursor: List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:\n  cursor\n');
 expect(proof.relationOf('relay',0,[])).toBe('Same');
});
test('strict suffix summaries compose through another function',async()=>{
 const proof=await analyze('def forwarded(tokens: List<&2, Lexer.Token>) -> Maybe<&2, List<&2, Lexer.Token>>:\n  tail(tokens)\ndef tail(cursor: List<&2, Lexer.Token>) -> Maybe<&2, List<&2, Lexer.Token>>:\n  match cursor:\n    case head <> rest:\n      Some{rest}\n    case Nil{}:\n      None{}\n');
 expect(proof.relationOf('forwarded',0,[0],{path:[],constructor:'Some'})).toBe('StrictSuffix');
});
test('success and failure provenance remain distinct result alternatives',async()=>{
 const proof=await analyze('def branch(tokens: List<&2, Lexer.Token>) -> List<&2, Lexer.Token> & Bool:\n  match tokens:\n    case head <> rest:\n      (rest, True{})\n    case Nil{}:\n      (tokens, False{})\n');
 expect(proof.relationOf('branch',0,[0],{path:[1],constructor:'True'})).toBe('StrictSuffix');
 expect(proof.relationOf('branch',0,[0],{path:[1],constructor:'False'})).toBe('Same');
 expect(proof.relationOf('branch',0,[0])).toBe('Suffix');
});
test('a success-only consumer uses only strict result provenance',async()=>{
 const proof=await analyze('def successful(tokens: List<&2, Lexer.Token>) -> Maybe<&2, List<&2, Lexer.Token>>:\n  result = branch(tokens)\n  match result:\n    case (cursor, True{}):\n      Some{cursor}\n    case (cursor, False{}):\n      None{}\ndef branch(tokens: List<&2, Lexer.Token>) -> List<&2, Lexer.Token> & Bool:\n  match tokens:\n    case head <> rest:\n      (rest, True{})\n    case Nil{}:\n      (tokens, False{})\n');
 expect(proof.relationOf('successful',0,[0],{path:[],constructor:'Some'})).toBe('StrictSuffix');
});
test('callback invocation receives and returns a strict suffix',async()=>{
 const proof=await analyze('def invoke(cursor: List<&2, Lexer.Token>, use: List<&2, Lexer.Token> -> List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:\n  use(cursor)\ndef callback_tail(tokens: List<&2, Lexer.Token>) -> Maybe<&2, List<&2, Lexer.Token>>:\n  match tokens:\n    case head <> rest:\n      Some{invoke(rest, current => current)}\n    case Nil{}:\n      None{}\n');
 expect(proof.relationOf('callback_tail',0,[0],{path:[],constructor:'Some'})).toBe('StrictSuffix');
});
test('nested callback and product projection retain strict provenance',async()=>{
 const proof=await analyze('def invoke(cursor: List<&2, Lexer.Token>, use: List<&2, Lexer.Token> -> List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:\n  use(cursor)\ndef unpack(pair: Bool & List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:\n  match pair:\n    case (flag, cursor):\n      cursor\ndef nested(tokens: List<&2, Lexer.Token>) -> Maybe<&2, List<&2, Lexer.Token>>:\n  match tokens:\n    case head <> rest:\n      Some{invoke(rest, current => invoke(unpack((True{}, current)), inner => inner))}\n    case Nil{}:\n      None{}\n');
 expect(proof.relationOf('nested',0,[0],{path:[],constructor:'Some'})).toBe('StrictSuffix');
});
test('recursive summaries converge and join identity with strict suffix',async()=>{
 const proof=await analyze('def walk(tokens: List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:\n  match tokens:\n    case head <> rest:\n      walk(rest)\n    case Nil{}:\n      tokens\n');
 expect(proof.relationOf('walk',0,[])).toBe('Suffix');
 expect(proof.iterations).toBeLessThan(10);
});
test('declared product inputs retain separate token field identities',async()=>{
 const proof=await analyze('def project(pair: Bool & List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:\n  match pair:\n    case (flag, cursor):\n      cursor\n');
 expect(proof.relationOf('project',0,[])).toBe('Same');
});
test('callback callsite evidence composes through its invoking helper',async()=>{
 const proof=await analyze('def invoke(cursor: List<&2, Lexer.Token>, use: List<&2, Lexer.Token> -> List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:\n  use(cursor)\ndef identity(cursor: List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:\n  cursor\ndef callback_site(tokens: List<&2, Lexer.Token>) -> Maybe<&2, List<&2, Lexer.Token>>:\n  match tokens:\n    case head <> rest:\n      Some{invoke(rest, current => identity(current))}\n    case Nil{}:\n      None{}\n');
 expect(proof.transitions.find(t=>t.caller==='callback_site'&&t.callee==='identity')?.relation).toBe('StrictSuffix');
});
test('an opaque callback result cannot disappear beside a known identity branch',async()=>{
 const proof=await analyze('def choose(tokens: List<&2, Lexer.Token>, flag: Bool, use: List<&2, Lexer.Token> -> List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:\n  match flag:\n    case True{}:\n      tokens\n    case False{}:\n      use(tokens)\n');
 expect(proof.relationOf('choose',0,[])).toBe('Unknown');
});
test('a constructed list branch cannot be discarded beside a strict branch',async()=>{
 const proof=await analyze('def mixed(tokens: List<&2, Lexer.Token>) -> Maybe<&2, List<&2, Lexer.Token>>:\n  match tokens:\n    case head <> rest:\n      Some{rest}\n    case Nil{}:\n      Some{Nil{}}\n');
 expect(proof.relationOf('mixed',0,[0],{path:[],constructor:'Some'})).toBe('Unknown');
});
test('callback names shadow inputs without aliasing their binder identities',async()=>{
 const proof=await analyze('def invoke(cursor: List<&2, Lexer.Token>, use: List<&2, Lexer.Token> -> List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:\n  use(cursor)\ndef shadow(tokens: List<&2, Lexer.Token>) -> Maybe<&2, List<&2, Lexer.Token>>:\n  match tokens:\n    case head <> rest:\n      Some{invoke(rest, tokens => tokens)}\n    case Nil{}:\n      None{}\n');
 expect(proof.relationOf('shadow',0,[0],{path:[],constructor:'Some'})).toBe('StrictSuffix');
});
test('opaque recursive cursor fields prevent a whole-argument consuming claim',async()=>{
 const proof=await analyze('type CursorBag is Data:\n  Bag{cursor: List<&2, Lexer.Token>, children: List<&2, CursorBag>}\ndef project(bag: CursorBag) -> List<&2, Lexer.Token>:\n  match bag:\n    case Bag{cursor, children}:\n      cursor\ndef pass(tokens: List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:\n  project(Bag{tokens, Nil{}})\n');
 expect(proof.transitions.find(t=>t.caller==='pass'&&t.callee==='project')?.relation).toBe('Unknown');
});
test('constructor fields preserve original and active aliases as Same across a match',async()=>{
 const proof=await analyze('type CursorState is Data:\n  A{original: List<&2, Lexer.Token>, active: List<&2, Lexer.Token>}\ndef make(tokens: List<&2, Lexer.Token>) -> CursorState:\n  A{tokens, tokens}\ndef aliases(state: CursorState) -> List<&2, Lexer.Token> & List<&2, Lexer.Token>:\n  match state:\n    case A{original, active}:\n      (original, active)\ndef entry(tokens: List<&2, Lexer.Token>) -> List<&2, Lexer.Token> & List<&2, Lexer.Token>:\n  aliases(make(tokens))\n');
 expect(proof.fieldRelationOf('aliases',[0],[1])).toBe('Same');
 expect(proof.fieldRelationOf('aliases',[1],[0])).toBe('Same');
 expect(proof.relationOf('entry',0,[1])).toBe('Same');
});
test('constructor fields preserve a possibly unchanged active suffix across a function boundary',async()=>{
 const proof=await analyze('type CursorState is Data:\n  A{original: List<&2, Lexer.Token>, active: List<&2, Lexer.Token>}\ndef suffix(tokens: List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:\n  match tokens:\n    case head <> rest:\n      suffix(rest)\n    case Nil{}:\n      tokens\ndef make(tokens: List<&2, Lexer.Token>) -> CursorState:\n  A{tokens, suffix(tokens)}\ndef expose(state: CursorState) -> List<&2, Lexer.Token> & List<&2, Lexer.Token>:\n  match state:\n    case A{original, active}:\n      (original, active)\ndef entry(tokens: List<&2, Lexer.Token>) -> List<&2, Lexer.Token> & List<&2, Lexer.Token>:\n  expose(make(tokens))\n');
 expect(proof.fieldRelationOf('expose',[1],[0])).toBe('Suffix');
 expect(proof.fieldRelationOf('expose',[0],[1])).toBe('Unknown');
 expect(proof.relationOf('entry',0,[1])).toBe('Suffix');
});
test('matching the active field tail proves a strict suffix of the original field',async()=>{
 const proof=await analyze('type CursorState is Data:\n  A{original: List<&2, Lexer.Token>, active: List<&2, Lexer.Token>}\ndef suffix(tokens: List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:\n  match tokens:\n    case head <> rest:\n      suffix(rest)\n    case Nil{}:\n      tokens\ndef make(tokens: List<&2, Lexer.Token>) -> CursorState:\n  A{tokens, suffix(tokens)}\ndef consume(state: CursorState) -> Maybe<&2, List<&2, Lexer.Token> & List<&2, Lexer.Token>>:\n  match state:\n    case A{original, active}:\n      match active:\n        case head <> rest:\n          Some{(original, rest)}\n        case Nil{}:\n          None{}\n');
 expect(proof.fieldRelationOf('consume',[0,1],[0,0],{path:[],constructor:'Some'})).toBe('StrictSuffix');
});
test('conversion from constructor A to B preserves the active suffix relation',async()=>{
 const proof=await analyze('type CursorState is Data:\n  A{original: List<&2, Lexer.Token>, active: List<&2, Lexer.Token>}\n  B{original: List<&2, Lexer.Token>, active: List<&2, Lexer.Token>}\ndef suffix(tokens: List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:\n  match tokens:\n    case head <> rest:\n      suffix(rest)\n    case Nil{}:\n      tokens\ndef make(tokens: List<&2, Lexer.Token>) -> CursorState:\n  A{tokens, suffix(tokens)}\ndef convert(state: CursorState) -> CursorState:\n  match state:\n    case A{original, active}:\n      B{original, active}\ndef expose(state: CursorState) -> List<&2, Lexer.Token> & List<&2, Lexer.Token>:\n  match state:\n    case B{original, active}:\n      (original, active)\n');
 expect(proof.fieldRelationOf('convert',[1],[0],{path:[],constructor:'B'})).toBe('Suffix');
 expect(proof.fieldRelationOf('expose',[1],[0])).toBe('Suffix');
});
test('conversion from constructor B to A records the new strict active suffix',async()=>{
 const proof=await analyze('type CursorState is Data:\n  A{original: List<&2, Lexer.Token>, active: List<&2, Lexer.Token>}\n  B{original: List<&2, Lexer.Token>, active: List<&2, Lexer.Token>}\ndef make(tokens: List<&2, Lexer.Token>) -> CursorState:\n  B{tokens, tokens}\ndef consume(state: CursorState) -> Maybe<&2, CursorState>:\n  match state:\n    case B{original, active}:\n      match active:\n        case head <> rest:\n          Some{A{original, rest}}\n        case Nil{}:\n          None{}\ndef expose(state: CursorState) -> List<&2, Lexer.Token> & List<&2, Lexer.Token>:\n  match state:\n    case A{original, active}:\n      (original, active)\n');
 expect(proof.fieldRelationOf('make',[1],[0],{path:[],constructor:'B'})).toBe('Same');
 expect(proof.fieldRelationOf('consume',[0,1],[0,0],{path:[],constructor:'Some'})).toBe('StrictSuffix');
 expect(proof.fieldRelationOf('expose',[1],[0])).toBe('StrictSuffix');
});
test('unrelated constructor token fields never acquire a suffix relation',async()=>{
 const proof=await analyze('type CursorState is Data:\n  A{original: List<&2, Lexer.Token>, active: List<&2, Lexer.Token>}\ndef make(original: List<&2, Lexer.Token>, active: List<&2, Lexer.Token>) -> CursorState:\n  A{original, active}\ndef expose(state: CursorState) -> List<&2, Lexer.Token> & List<&2, Lexer.Token>:\n  match state:\n    case A{original, active}:\n      (original, active)\n');
 expect(proof.fieldRelationOf('expose',[0],[1])).toBe('Unknown');
 expect(proof.fieldRelationOf('expose',[1],[0])).toBe('Unknown');
 expect(proof.relationOf('make',0,[1])).toBe('Unknown');
 expect(proof.relationOf('make',1,[1])).toBe('Same');
});
test('merging related and unrelated constructor branches keeps Unknown and branch evidence',async()=>{
 const proof=await analyze('type CursorState is Data:\n  A{original: List<&2, Lexer.Token>, active: List<&2, Lexer.Token>}\n  B{original: List<&2, Lexer.Token>, active: List<&2, Lexer.Token>}\ndef suffix(tokens: List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:\n  match tokens:\n    case head <> rest:\n      suffix(rest)\n    case Nil{}:\n      tokens\ndef choose(tokens: List<&2, Lexer.Token>, other: List<&2, Lexer.Token>, flag: Bool) -> CursorState:\n  match flag:\n    case True{}:\n      A{tokens, suffix(tokens)}\n    case False{}:\n      B{tokens, other}\ndef expose(state: CursorState) -> CursorState:\n  match state:\n    case A{original, active}:\n      A{original, active}\n    case B{original, active}:\n      B{original, active}\n');
 expect(proof.fieldRelationOf('expose',[1],[0])).toBe('Unknown');
 expect(proof.fieldRelationOf('expose',[1],[0],{path:[],constructor:'A'})).toBe('Suffix');
 expect(proof.fieldRelationOf('expose',[1],[0],{path:[],constructor:'B'})).toBe('Unknown');
 expect(proof.relationOf('choose',0,[1])).toBe('Unknown');
 expect(proof.relationOf('choose',0,[1],{path:[],constructor:'A'})).toBe('Suffix');
 expect(proof.relationOf('choose',0,[1],{path:[],constructor:'B'})).toBe('Unknown');
});
test('nested constructor and product paths retain strict field provenance after matching',async()=>{
 const proof=await analyze('type InnerState is Data:\n  Inner{original: List<&2, Lexer.Token>, active: List<&2, Lexer.Token>}\ntype OuterState is Data:\n  Outer{payload: Bool & InnerState}\ndef make(tokens: List<&2, Lexer.Token>) -> OuterState:\n  Outer{(True{}, Inner{tokens, tokens})}\ndef consume(state: OuterState) -> Maybe<&2, OuterState>:\n  match state:\n    case Outer{payload}:\n      match payload:\n        case (flag, Inner{original, active}):\n          match active:\n            case head <> rest:\n              Some{Outer{(flag, Inner{original, rest})}}\n            case Nil{}:\n              None{}\n');
 expect(proof.fieldRelationOf('make',[0,1,1],[0,1,0])).toBe('Same');
 expect(proof.fieldRelationOf('consume',[0,0,1,1],[0,0,1,0],{path:[],constructor:'Some'})).toBe('StrictSuffix');
});
test('a helper call followed by construction and matching preserves field relations',async()=>{
 const proof=await analyze('type CursorState is Data:\n  A{original: List<&2, Lexer.Token>, active: List<&2, Lexer.Token>}\n  B{original: List<&2, Lexer.Token>, active: List<&2, Lexer.Token>}\ndef suffix(tokens: List<&2, Lexer.Token>) -> List<&2, Lexer.Token>:\n  match tokens:\n    case head <> rest:\n      suffix(rest)\n    case Nil{}:\n      tokens\ndef make(tokens: List<&2, Lexer.Token>) -> CursorState:\n  A{tokens, suffix(tokens)}\ndef active_of(state: CursorState) -> List<&2, Lexer.Token>:\n  match state:\n    case A{original, active}:\n      active\ndef repack(state: CursorState) -> CursorState:\n  match state:\n    case A{original, active}:\n      current = active_of(A{original, active})\n      B{original, current}\ndef project(state: CursorState) -> List<&2, Lexer.Token> & List<&2, Lexer.Token>:\n  result = repack(state)\n  match result:\n    case B{original, active}:\n      (original, active)\ndef entry(tokens: List<&2, Lexer.Token>) -> List<&2, Lexer.Token> & List<&2, Lexer.Token>:\n  project(make(tokens))\n');
 expect(proof.fieldRelationOf('project',[1],[0])).toBe('Suffix');
 expect(proof.fieldRelationOf('entry',[1],[0])).toBe('Suffix');
 expect(proof.relationOf('entry',0,[1])).toBe('Suffix');
});
