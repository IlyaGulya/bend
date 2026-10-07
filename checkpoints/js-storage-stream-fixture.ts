import * as B from '../bend2/bend.ts';
import * as Normal from '../bend2/comp.ts';
import * as Stream from '../bend2/.comp_js_stream_probe.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {mkdtempSync,writeFileSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {createHash} from 'node:crypto';
await guardHeavyGate(import.meta.path,{label:'Existing JS per-definition emit/release parity'});
const dir=mkdtempSync(join(tmpdir(),'bend-js-stream-')),rows=[];
try{
 for(const [name,source,args,expected] of [
 ['constant','def main() -> Nat:\n  7n\n',[],7n],
 ['callee','def plus(x: Nat) -> Nat:\n  Succ{x}\ndef main(x: Nat) -> Nat:\n  plus(x)\n',[4n],5n],
 ['recursive','def count(x: Nat) -> Nat:\n  match x:\n    case Zero{}: 0n\n    case Succ{n}: Succ{count(n)}\ndef main(x: Nat) -> Nat:\n  count(x)\n',[6n],6n],
 ['raised-arity','def lifted() -> (Nat -> Nat):\n  x => x\ndef main() -> Nat:\n  lifted()(7n)\n',[],7n],
 ['shared-tables','def one(x: Nat) -> Nat:\n  match x:\n    case Zero{}: 1n\n    case Succ{n}: 2n\ndef two(x: Nat) -> Nat:\n  match x:\n    case Zero{}: 3n\n    case Succ{n}: 4n\ndef main(x: Nat) -> Nat:\n  two(one(x))\n',[0n],4n]
 ] as const){
  const file=join(dir,'main.bend');writeFileSync(file,'import Base\n\n'+source);const a=B.book_nil(),b=B.book_nil();for(const book of [a,b]){await B.book_load(book,file,'',new Map());B.book_valid(book);if(book.hols||book.open)throw Error('Incomplete validation');}
  const original=Normal.js_lib(a,['main'],['main']);Stream.js_storage_release_e(true);const streamed=Stream.js_lib(b,['main'],['main']);
  if(original!==streamed)throw Error('Stream JS bytes differ: '+name);
  const js=join(dir,name+'.js');writeFileSync(js,streamed);
  const child=Bun.spawn([process.execPath,'--eval',`const value=(await import(${JSON.stringify(js)})).default.main(${args.map(v=>v+'n').join(',')});if(value!==${expected}n)throw Error('Runtime mismatch');console.log(String(value));`],{stdout:'pipe',stderr:'pipe'});
  const actual=(await new Response(child.stdout).text()).trim(),stderr=await new Response(child.stderr).text();if(await child.exited)throw Error(stderr);
  rows.push({name,nativeValidation:'PASS both',jsBytesEqual:true,jsSha256:createHash('sha256').update(streamed).digest('hex'),actual,expected:String(expected)});
 }
 writeFileSync('/Users/ilyagulya/Projects/My/bend/checkpoints/js-storage-stream-fixtures.json',JSON.stringify({status:'PASS',rows},null,2)+'\n');console.log(JSON.stringify(rows));
}finally{rmSync(dir,{recursive:true,force:true});}
