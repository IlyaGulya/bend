import * as B from '../bend2/bend.ts';
import * as Comp from '../bend2/comp.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {mkdtempSync,writeFileSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join,resolve} from 'node:path';
await guardHeavyGate(import.meta.path,{label:'Native TokenInfo Local annotation fixture'});
const dir=mkdtempSync(join(tmpdir(),'bend-token-annotation-'));
const lexer=(await Bun.file('bend2/selfhost/lexer.bend').text()).split('\n').slice(0,14).join('\n')+'\n';
const initializer='Lexer.TokenInfo{Lexer.SymbolToken{}, "-", start + 1n, end, line, column + 1n}';
const rows:any[]=[];
try{
 writeFileSync(join(dir,'lexer.bend'),lexer);
 for(const variant of ['unannotated','annotated','reference']){
  const body=variant==='reference'?initializer:`erased = ${variant==='annotated'?'{ '+initializer+' : Lexer.Token }':initializer}\n  erased`;
  const source=`import Base\nimport ./lexer.bend as Lexer\ndef example(+start: Nat, end: Nat, line: Nat, +column: Nat) -> Lexer.Token:\n  ${body}\n`;
  const file=join(dir,'main.bend');writeFileSync(file,source);
  const book=B.book_nil();await B.book_load(book,file,'',new Map());
  const row:any={variant};
  try{B.book_valid(book);row.valid=true;}catch(error){row.valid=false;row.diagnostic=(error as any)?.$==='Err'?B.err_show(error as B.Err):String(error);}
  if(variant==='unannotated'){
   if(row.valid||!row.diagnostic.includes('cannot infer'))throw Error('Expected unannotated Local inference failure');
  }else{
   if(!row.valid)throw Error(row.diagnostic);
   const js=Comp.js_lib(book,true,{roots:['example'],exports:['example']});
   const lib=new Function(js.replace('export default {','return {'))();row.output=JSON.stringify(lib.example(10n,20n,30n,40n),(_,value)=>typeof value==='bigint'?String(value):value);
  }
  rows.push(row);
 }
 if(rows[1].output!==rows[2].output)throw Error('Annotation changed runtime token fields');
 const report={status:'PASS',verifiedConstructorType:'Lexer.Token',declarations:'Exact current lexer.bend lines 1–14',ownership:'Unchanged source quantities; full native validation for annotated and direct-constructor reference',rows};
 writeFileSync(resolve('checkpoints/parser-token-annotation-smoke.json'),JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report));
}finally{rmSync(dir,{recursive:true,force:true});}
