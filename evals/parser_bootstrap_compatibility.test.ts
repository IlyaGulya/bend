import {expect,test} from 'bun:test';
import * as B from '../bend2/bend.ts';
import {canonicalSourceBook} from './parser_full_semantic_normalize.ts';
import {resolve} from 'node:path';
import {installCompiledLexerABI,feedbackParserResult} from './bootstrap_parser_eval_abi.ts';
const parserPath=process.env.BOOTSTRAP_PARSER_SOURCE??'bend2/selfhost/parser.bend';
const entryPoint=process.env.BOOTSTRAP_PARSER_ENTRYPOINT??'parse';
if(!['parse','parse_with_fuel'].includes(entryPoint))throw Error('Unsupported public parser entry point');
const book=await canonicalSourceBook(await Bun.file(parserPath).text(), resolve(parserPath));
if(entryPoint==='parse_with_fuel')await installCompiledLexerABI(book);
let fuel:B.HTerm=B.Ctr('FeedbackFuelEnd',[]);
if(entryPoint==='parse_with_fuel')for(let i=0;i<2000000;i++)fuel=B.Ctr('FeedbackFuelCell',[fuel]);
function closed(source:string){const p:B.Parse={book,dir:resolve('bend2/selfhost')+'/',str:JSON.stringify(source),pos:0,stk:[],frs:0,ns:'',al:{Ast:'ast',Lexer:'lexer'}};return B.term_higher(B.parse_term(p));}
// Public spelling is name_key; Lit unfolds only when this observer needs a head.
function ctor(t:B.HTerm){const raw=B.term_wnf(book,t),v=raw.$==='Lit'?B.lit_step(raw):raw;if(v.$!=='Ctr')throw Error('Expected AST constructor');return {...v,k:B.name_key(v.k).split('.').at(-1)!};}
function parse(source:string){
 if(entryPoint==='parse')return ctor(B.App(B.App(B.Ref(entryPoint),closed('bootstrap-grammar')),closed(source)));
 const run=ctor(B.App(B.App(B.App(B.Ref(entryPoint),fuel),closed('bootstrap-grammar')),closed(source)));
 return ctor(feedbackParserResult(book,run));
}
test('indexed datatype erased parameter is preserved with adjacent or spaced opening syntax',()=>{
 for(const open of ['<-p','< -p']){
  const result=parse('type Indexed'+open+': Nat> is Data:\n  IndexedValue{}\n');
  expect(result.k).toBe('ParseSuccess');
  const module=ctor(result.x[0]),declarations=ctor(module.x[2]);
  const declaration=ctor(ctor(declarations.x[0]).x[0]),parameter=ctor(ctor(declaration.x[1]).x[0]);
  expect(parameter.k).toBe('Binder');
  expect(ctor(parameter.x[0]).k).toBe('QZero');
  expect(ctor(parameter.x[3]).k).toBe('TermRef');
  expect(ctor(ctor(declaration.x[1]).x[1]).k).toBe('Nil');
 }
});
test('cons patterns associate right and preserve reusable bindings',()=>{
 const result=parse('def f(xs: Nat) -> Nat:\n  match xs:\n    case +head <> tail <> Nil{}: head\n');
 expect(result.k).toBe('ParseSuccess');
 const module=ctor(result.x[0]),definition=ctor(ctor(ctor(module.x[2]).x[0]).x[0]);
 const match=ctor(ctor(definition.x[3]).x[0]);
 expect(match.k).toBe('BodyMatch');
 const branch=ctor(ctor(match.x[1]).x[0]),outer=ctor(ctor(branch.x[0]).x[0]);
 expect(outer.k).toBe('PatternCtr');
 const fields=ctor(outer.x[1]),head=ctor(fields.x[0]),tail=ctor(ctor(fields.x[1]).x[0]);
 expect(ctor(head.x[2]).k).toBe('QMany');
 expect(tail.k).toBe('PatternCtr');
 expect(ctor(ctor(tail.x[1]).x[0]).k).toBe('PatternVar');
 expect(ctor(ctor(ctor(tail.x[1]).x[1]).x[0]).k).toBe('PatternCtr');
 expect(ctor(ctor(branch.x[1]).x[0]).k).toBe('TermVar');
},30000);
test('tuple patterns preserve nesting, right association and grouping delimiters',()=>{
 function pattern(text:string){
  const result=parse('def f(x: Nat) -> Nat:\n  match x:\n    case '+text+': 0n\n');
  if(result.k!=='ParseSuccess')return result;
  const module=ctor(result.x[0]),definition=ctor(ctor(ctor(module.x[2]).x[0]).x[0]);
  const match=ctor(ctor(definition.x[3]).x[0]),branch=ctor(ctor(match.x[1]).x[0]);
  return ctor(ctor(branch.x[0]).x[0]);
 }
 const flat=pattern('(a,b,c)'),fields=ctor(flat.x[1]);
 expect(flat.k).toBe('PatternCtr');
 expect(ctor(fields.x[0]).k).toBe('PatternVar');
 expect(ctor(ctor(fields.x[1]).x[0]).k).toBe('PatternCtr');
 const nested=pattern('((a,b),c)');
 expect(ctor(ctor(nested.x[1]).x[0]).k).toBe('PatternCtr');
 expect(pattern('(a)').k).toBe('PatternVar');
 for(const invalid of ['()', '(a,)', '(a,b', '(a b)'])expect(pattern(invalid).k).toBe('ParseFailure');
},120000);
test('character literal patterns preserve plain and escaped codepoints',()=>{
 function text(t:B.HTerm){let out='';for(;;){const s=ctor(t);if(s.k==='SNil')return out;let w=ctor(ctor(s.x[0]).x[0]).x[0],n=0,bit=1;for(;;){const cell=ctor(w);if(cell.k==='WNil')break;if(ctor(cell.x[0]).k==='True')n+=bit;bit*=2;w=cell.x[1];}out+=String.fromCodePoint(n);t=s.x[1];}}
 function fields(t:B.HTerm){return ctor(ctor(t).x[1]);}
 for(const [literal,expected] of [["'A'",65],["'\\n'",10],["'\\u{41}'",65]] as const){
  const result=parse('def f(x: Nat) -> Nat:\n  match x:\n    case '+literal+': 0n\n');
  expect(result.k).toBe('ParseSuccess');
  const module=ctor(result.x[0]),definition=ctor(ctor(ctor(module.x[2]).x[0]).x[0]),match=ctor(ctor(definition.x[3]).x[0]),branch=ctor(ctor(match.x[1]).x[0]),pattern=ctor(ctor(branch.x[0]).x[0]);
  expect(text(pattern.x[0])).toBe('Chr');
  const integer=fields(pattern as B.HTerm).x[0];expect(text(ctor(integer).x[0])).toBe('U32');
  let word=fields(integer).x[0],value=0,bit=1;
  for(;;){const node=ctor(word),name=text(node.x[0]);if(name==='WNil')break;expect(name).toBe('WCon');const fs=fields(word);if(text(ctor(fs.x[0]).x[0])==='True')value+=bit;bit*=2;word=ctor(fs.x[1]).x[0];}
  expect(value).toBe(expected);
 }
},120000);
test('multi-scrutinee matches accept whitespace or comma separators and check case arity',()=>{
 function body(source:string){
  const result=parse(source);if(result.k!=='ParseSuccess')return result;
  const module=ctor(result.x[0]),definition=ctor(ctor(ctor(module.x[2]).x[0]).x[0]);
  return ctor(ctor(definition.x[3]).x[0]);
 }
 for(const [scrutinees,patterns] of [['x y','Zero{} Zero{}'],['x, y','Zero{}, Zero{}']]){
  const match=body('def f(x: Nat, y: Nat) -> Nat:\n  match '+scrutinees+':\n    case '+patterns+': 0n\n    case +a +b: a\n');
  expect(match.k).toBe('BodyMatch');
  expect(ctor(ctor(ctor(match.x[0]).x[1]).x[1]).k).toBe('Nil');
  const second=ctor(ctor(ctor(match.x[1]).x[1]).x[0]),bindings=ctor(second.x[0]);
  expect(ctor(ctor(bindings.x[0]).x[2]).k).toBe('QMany');
  expect(ctor(ctor(ctor(bindings.x[1]).x[0]).x[2]).k).toBe('QMany');
  expect(ctor(ctor(second.x[1]).x[0]).k).toBe('TermVar');
 }
 expect(body('def f(x: Nat, y: Nat) -> Nat:\n  match x y:\n    case Zero{}: 0n\n').k).toBe('ParseFailure');
},120000);
test('natural-prefix patterns bind the tail and require adjacent plus syntax',()=>{
 function branch(prefix:string){
  const result=parse('def f(x: Nat) -> Nat:\n  match x:\n    case '+prefix+': tail\n');
  if(result.k!=='ParseSuccess')return result;
  const module=ctor(result.x[0]),definition=ctor(ctor(ctor(module.x[2]).x[0]).x[0]),match=ctor(ctor(definition.x[3]).x[0]);
  return ctor(ctor(match.x[1]).x[0]);
 }
 const zero=branch('0n+tail');expect(ctor(ctor(zero.x[0]).x[0]).k).toBe('PatternVar');
 const two=branch('2n+ tail');let pattern=ctor(ctor(two.x[0]).x[0]);
 for(let n=0;n<2;n++){expect(pattern.k).toBe('PatternCtr');pattern=ctor(ctor(pattern.x[1]).x[0]);}
 expect(pattern.k).toBe('PatternVar');
 expect(ctor(ctor(two.x[1]).x[0]).k).toBe('TermVar');
 expect(branch('1n +tail').k).toBe('ParseFailure');
 expect(branch('257n+tail').k).toBe('ParseFailure');
},120000);
test('unsafe annotations preserve the definition token across line boundaries',()=>{
 for(const annotation of ['@unsafe\n','@unsafe ']){
  const result=parse(annotation+'def f(x: Nat) -> Nat:\n  x\n');
  expect(result.k).toBe('ParseSuccess');
  const module=ctor(result.x[0]),definition=ctor(ctor(ctor(module.x[2]).x[0]).x[0]);
  expect(definition.k).toBe('Definition');
  expect(ctor(definition.x[4]).k).toBe('True');
 }
 expect(parse('@unsafe notdef f(x: Nat) -> Nat:\n  x\n').k).toBe('ParseFailure');
},120000);
test('natural expression adjacency distinguishes prefix constructors from addition',()=>{
 function expression(text:string){
  const result=parse('def f(x: Nat) -> Nat:\n  '+text+'\n');expect(result.k).toBe('ParseSuccess');
  const module=ctor(result.x[0]),definition=ctor(ctor(ctor(module.x[2]).x[0]).x[0]);
  return ctor(ctor(ctor(definition.x[3]).x[0]).x[0]);
 }
 expect(expression('1n + x').k).toBe('TermApp');
 expect(expression('1n+x').k).toBe('TermCtr');
 expect(expression('1n+ x').k).toBe('TermCtr');
},120000);
test('cons expression RHS grouping remains a constructor, not empty type application',()=>{
 for(const expression of ['x <> (y <> xs)','x<>(y <> xs)','x <> [y]']){
  const result=parse('def f(x: Nat, y: Nat, xs: List<&2, Nat>) -> List<&2, Nat>:\n  '+expression+'\n');
  expect(result.k).toBe('ParseSuccess');
  const module=ctor(result.x[0]),definition=ctor(ctor(ctor(module.x[2]).x[0]).x[0]),body=ctor(ctor(ctor(definition.x[3]).x[0]).x[0]);
  expect(body.k).toBe('TermCtr');
  const arguments_=ctor(body.x[1]);expect(ctor(arguments_.x[0]).k).toBe('TermVar');
  expect(ctor(ctor(arguments_.x[1]).x[0]).k).toBe('TermCtr');
 }
},120000);
test('local tuple destructuring uses the following body and retains nested patterns',()=>{
 for(const [pattern,binding] of [['(a,b)','a'],['((a,b),c)','b']]){
  const result=parse('def f(p: Nat & Nat) -> Nat:\n  '+pattern+' = p\n  '+binding+'\n');
  expect(result.k).toBe('ParseSuccess');
  const module=ctor(result.x[0]),definition=ctor(ctor(ctor(module.x[2]).x[0]).x[0]),local=ctor(ctor(definition.x[3]).x[0]);
  expect(local.k).toBe('BodyLocal');
  expect(ctor(ctor(local.x[0]).x[0]).k).toBe('PatternCtr');
  expect(ctor(ctor(local.x[3]).x[0]).k).toBe('TermVar');
 }
},120000);
test('nested generic closing angles do not become a shift operator',()=>{
 const result=parse('def f(x: List<&2, List<&2, Nat>>) -> Nat:\n  0n\n');
 expect(result.k).toBe('ParseSuccess');
 const module=ctor(result.x[0]),definition=ctor(ctor(ctor(module.x[2]).x[0]).x[0]),binder=ctor(ctor(definition.x[1]).x[0]),outer=ctor(binder.x[3]);
 expect(outer.k).toBe('TermFill');
 expect(ctor(ctor(ctor(outer.x[1]).x[1]).x[0]).k).toBe('TermFill');
},120000);
test('empty match parses absurd elimination without consuming the next declaration',()=>{
 const result=parse('def f(e: Empty) -> Nat:\n  match e:\ndef next() -> Nat:\n  0n\n');
 expect(result.k).toBe('ParseSuccess');
 const module=ctor(result.x[0]),declarations=ctor(module.x[2]),definition=ctor(ctor(declarations.x[0]).x[0]),body=ctor(ctor(definition.x[3]).x[0]);
 expect(body.k).toBe('BodyMatch');
 expect(ctor(body.x[1]).k).toBe('Nil');
 expect(ctor(declarations.x[1]).k).toBe('Con');
 expect(ctor(ctor(declarations.x[1]).x[1]).k).toBe('Nil');
},120000);
test('pair type chains remain right associated across generic operands',()=>{
 for(const type of ['Nat & Nat & Nat','List<&2, Nat> & List<&2, Nat> & List<&2, Nat>']){
  const result=parse('def f() -> '+type+':\n  (0n, 0n, 0n)\n');
  expect(result.k).toBe('ParseSuccess');
  const module=ctor(result.x[0]),definition=ctor(ctor(ctor(module.x[2]).x[0]).x[0]),outer=ctor(ctor(definition.x[2]).x[0]);
  expect(outer.k).toBe('TermApp');
  expect(ctor(outer.x[1]).k).toBe('TermApp');
  expect(ctor(ctor(outer.x[1]).x[0]).k).toBe('TermApp');
 }
},120000);
test('newline continues infix cons but not parenthesized application',()=>{
 const result=parse('def f(x: Nat, xs: List<&2, Nat>) -> List<&2, Nat>:\n  x\n    <> xs\n');
 expect(result.k).toBe('ParseSuccess');
 const module=ctor(result.x[0]),definition=ctor(ctor(ctor(module.x[2]).x[0]).x[0]),body=ctor(ctor(ctor(definition.x[3]).x[0]).x[0]);
 expect(body.k).toBe('TermCtr');
 const boundary=parse('def f(x: Nat) -> Nat:\n  y = x\n  (y)\n');
 expect(boundary.k).toBe('ParseSuccess');
 const nextModule=ctor(boundary.x[0]),nextDefinition=ctor(ctor(ctor(nextModule.x[2]).x[0]).x[0]),local=ctor(ctor(nextDefinition.x[3]).x[0]);
 expect(local.k).toBe('BodyLocal');
 expect(ctor(ctor(local.x[3]).x[0]).k).toBe('TermVar');
},120000);
