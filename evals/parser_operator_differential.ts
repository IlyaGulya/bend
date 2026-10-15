import * as B from '../bend2/bend.ts';
import {canonicalSourceBook,canonicalCore,normalizeCoreBook,normalizeImports,type Value} from './parser_full_semantic_normalize.ts';
import {installCompiledLexerABI,feedbackParserResult} from './bootstrap_parser_eval_abi.ts';
import {sourceOracle} from './bootstrap_source_oracle.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {writeFileSync,mkdtempSync,rmSync} from 'node:fs';
import {resolve,dirname,join} from 'node:path';
import {tmpdir} from 'node:os';
import {Readable} from 'node:stream';
import {createInterface} from 'node:readline';
await guardHeavyGate(import.meta.path,{label:'Four-layer operator-chain AST differential'});
const layer=process.argv.find(a=>a.startsWith('--layer='))?.slice(8)??'canonical';
const parserPath=process.argv.find(a=>a.startsWith('--parser='))?.slice(9)??({canonical:'bend2/selfhost/parser.bend',factored:'bend2/selfhost/.bootstrap_parser_rebuild_annotation-v1_source.bend',generated:'bend2/selfhost/.bootstrap_parser_rebuild_annotation-v1_generated_fuel.bend'} as any)[layer];
const artifact=process.argv.find(a=>a.startsWith('--artifact='))?.slice(11)??'checkpoints/bootstrap-parser-rebuild-annotation-v1.js';
const report=process.argv.find(a=>a.startsWith('--report='))?.slice(9)??'checkpoints/operator-'+layer+'.json';
const continuation=process.argv.includes('--continuation');
const continuationSources:Record<string,string>={
 'local-add-tuple':'def f(x: Nat, y: Nat) -> Nat & Bool:\n  bits = x + y\n  (bits, True{})\n',
 'local-simple-tuple':'def f(x: Nat, y: Nat) -> Nat & Bool:\n  bits = x\n  (bits, True{})\n',
 'local-add-variable':'def f(x: Nat, y: Nat) -> Nat:\n  bits = x + y\n  bits\n',
 'local-chain-tuple':'def f(x: Nat, y: Nat) -> Nat & Bool:\n  bits = x * 1n + y - 1n\n  (bits, True{})\n',
 'local-add-parenthesized':'def f(x: Nat, y: Nat) -> Nat:\n  bits = x + y\n  (bits)\n',
 'local-add-list':'def f(x: Nat, y: Nat) -> List<&2, Nat>:\n  bits = x + y\n  [bits]\n',
 'same-line-call':'def f(g: Nat -> Nat, x: Nat, y: Nat) -> Nat:\n  g(x + y)\n',
 'blank-line-tuple':'def f(x: Nat, y: Nat) -> Nat & Bool:\n  bits = x + y\n\n  (bits, True{})\n',
};
const expressions=continuation?Object.keys(continuationSources):['x * 1n + y','x + y','x + y + z','x * y','x * y * z','x * y + z','x + y * z','x - y + z','x + y - z','(x * y) + z','x * (y + z)'];
const rows:any[]=[];let book:B.Book|undefined,fuel:B.HTerm=B.Ctr('FeedbackFuelEnd',[]);
if(layer!=='compiled'){book=await canonicalSourceBook(await Bun.file(parserPath).text(), resolve(parserPath));await installCompiledLexerABI(book);if(layer==='generated')for(let i=0;i<2000000;i++)fuel=B.Ctr('FeedbackFuelCell',[fuel]);}
function closed(source:string):B.HTerm{let out=B.Ctr('SNil',[]);for(const c of Array.from(source).reverse())out=B.Ctr('SCon',[B.Ctr('Chr',[B.term_higher(B.u32_to_term(c.codePointAt(0)!))]),out]);return out;}
function ctor(t:B.HTerm){const value=B.term_wnf(book!,t);if(value.$!=='Ctr')throw Error('Expected constructor '+value.$);return value;}
function nat(t:B.HTerm){let n=0;for(;;){const v=ctor(t);if(v.k==='Zero')return n;if(v.k!=='Succ')throw Error('Bad Nat');n++;t=v.x[0]!;}}
function string(t:B.HTerm){let out='';for(;;){const v=ctor(t);if(v.k==='SNil')return out;let word=ctor(ctor(v.x[0]!).x[0]!).x[0]!,code=0,bit=1;for(;;){const w=ctor(word);if(w.k==='WNil')break;if(ctor(w.x[0]!).k==='True')code+=bit;bit*=2;word=w.x[1]!;}out+=String.fromCodePoint(code);t=v.x[1]!;}}
function decode(t:B.HTerm):Value{const v=ctor(t),tag=v.k.split('.').at(-1)!;if(tag==='Zero'||tag==='Succ')return nat(t);if(tag==='True'||tag==='False')return tag==='True';if(tag==='SNil'||tag==='SCon')return string(t);if(tag==='Nil'||tag==='Con'){const list:Value[]=[];while(true){const c=ctor(t);if(c.k==='Nil')return list;list.push(decode(c.x[0]!));t=c.x[1]!;}}return {tag,fields:v.x.map(decode)};}
function native(x:any):Value{if(x?.$==='$NativeNat')return Number(x.value);if(typeof x!=='object'||x===null)return x;if(x.$==='Nil'||x.$==='Con'){const out:Value[]=[];while(x.$==='Con'){out.push(native(x.head));x=x.tail;}return out;}return {tag:x.$.split('.').at(-1),fields:Object.entries(x).filter(([k])=>k!=='$').map(([,v])=>native(v))};}
const trace:any[]=[];
if(book&&layer==='canonical'&&process.argv.includes('--trace')){
 for(const [name,tokenIndex,levelIndex,priorityIndex] of [['parse_term_tail',2,5,-1],['parse_term_tail_after_line',2,5,-1],['parse_operator_precedence',5,8,3]] as const){
  const def=book.tlds[name];if(def?.$!=='Def')throw Error('Missing trace helper');
  const original=def.v!,arity=def.n;
  function wrap(term:B.HTerm,args:B.HTerm[]):B.HTerm{
   if(args.length<arity)return B.Lam('diagnostic',100000+args.length,arg=>wrap(B.App(term,arg),args.concat(arg)));
   const event:any={helper:name,level:nat(args[levelIndex]!),priority:priorityIndex<0?undefined:nat(args[priorityIndex]!),inputTokens:decode(args[tokenIndex]!)};
   trace.push(event);const output=B.term_wnf(book!,term);event.result=decode(output);return output;
  }
  def.v=wrap(original,[]);
 }
}
const worker=layer==='compiled'?Bun.spawn(['node','evals/bootstrap_parser_artifact_worker.mjs',resolve(artifact)],{stdin:'pipe',stdout:'pipe',stderr:'inherit'}):undefined;
const lines=worker?createInterface({input:Readable.fromWeb(worker.stdout as any)}):undefined,iterator=lines?.[Symbol.asyncIterator]();
const fixtureDir=mkdtempSync(join(tmpdir(),'bend-operator-differential-'));
try{for(const [id,expression] of expressions.entries()){
 trace.length=0;
 const source=continuation?continuationSources[expression]!:id===0?'def f(x: Nat, y: Nat) -> Nat:\n  x * 1n + y\n':`def f(x: Nat, y: Nat, z: Nat) -> Nat:\n  ${expression}\n`;
 const file=join(fixtureDir,'source.bend');writeFileSync(file,source);const oracle=await sourceOracle(file,source),environment=oracle.normalizationBook();
 const expected=normalizeCoreBook(environment,oracle.declarations.map(d=>d.key),oracle.imports.map(i=>({path:i.path,alias:i.alias})),file,dirname(file)+'/').semantic;
 let result:any;
 if(worker){worker.stdin.write(JSON.stringify({id,file,source})+'\n');await worker.stdin.flush();const line=await iterator!.next();if(line.done)throw Error('Worker ended');const response=JSON.parse(line.value);if(response.error)throw Error(response.error);result=native(response.result);}
 else{let term:B.HTerm;if(layer==='generated')term=feedbackParserResult(book!,B.App(B.App(B.App(B.Ref('parse_with_fuel'),fuel),closed(file)),closed(source)));else term=B.App(B.App(B.Ref('parse'),closed(file)),closed(source));result=decode(term);}
 const accepted=result.tag==='ParseSuccess',actual=accepted?canonicalCore(result.fields[0],environment,source).semantic:undefined;
 if(actual)actual.imports=normalizeImports(oracle.imports.map(i=>({path:i.path,alias:i.alias})));
 const row={expression,source,stage0Accepted:oracle.accepted,accepted,expected,actual,failure:accepted?undefined:result,semanticParity:accepted&&JSON.stringify(expected)===JSON.stringify(actual)};rows.push(row);console.log(JSON.stringify({layer,expression,accepted,semanticParity:row.semanticParity}));
 if(book&&!continuation){let scope:B.HTerm=B.Ctr('Nil',[]);for(let i=2;i>=0;i--){let n=B.Ctr('Zero',[]);for(let j=0;j<i;j++)n=B.Ctr('Succ',[n]);scope=B.Ctr('Con',[B.Ctr('Scope',[closed(['x','y','z'][i]!),n]),scope]);}const tokens=B.App(B.Ref('lexer.tokens'),closed(expression+'\n'));let n=B.Ctr('Zero',[]);for(let i=0;i<3;i++)n=B.Ctr('Succ',[n]);let value=[closed(file),tokens,scope,n,B.Ctr('Zero',[])].reduce((f,a)=>B.App(f,a),B.Ref(layer==='generated'?'step_parse_term':'parse_term'));if(layer==='generated'){const complete=ctor([fuel,value,B.Ctr('Nil',[])].reduce((f,a)=>B.App(f,a),B.Ref('feedback_drive')));value=ctor(complete.x[0]!).x[0]!;}row['expressionCursor' as keyof typeof row]=decode(value) as any;}
 if(process.argv.includes('--trace'))(row as any).trace=trace.slice();
 writeFileSync(report,JSON.stringify({layer,parserPath,artifact,rows,trace:process.argv.includes('--trace')?trace:undefined},null,2)+'\n');Bun.gc(true);
 if(process.argv.includes('--minimal-only'))break;
 }}finally{if(worker){lines!.close();worker.stdin.end();await worker.exited;}rmSync(fixtureDir,{recursive:true,force:true});}
