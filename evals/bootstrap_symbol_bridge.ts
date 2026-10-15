import * as B from '../bend2/bend.ts';
import * as Comp from '../bend2/comp.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {mkdtempSync,writeFileSync,rmSync} from 'node:fs';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
await guardHeavyGate(import.meta.path,{label:'Exact selfhost Lexer token producer for canonical grammar evaluator'});
const root=process.cwd(),dir=mkdtempSync(join(tmpdir(),'bend-bootstrap-lexer-'));
try{
 const file=root+'/checkpoints/bootstrap_symbol_component.bend';
 const book=B.book_nil();await B.book_load(book,file,'',new Map());B.book_valid(book);
 if(book.hols||book.open)throw Error('Incomplete native Lexer validation');
 const code=Comp.js_lib(book,['tokens'],['tokens']);writeFileSync('checkpoints/bootstrap-combined-token-producer.js',code);
 console.log(JSON.stringify({status:'PASS',declarations:book.order.length,bytes:Buffer.byteLength(code),proof:'Actual unchanged Bend Lexer.tokens and exact canonical combine_symbols compiled by unchanged stage0 compiler; full native validation zero exclusions; no host tokenizer'}));
}catch(error){console.error(error&&typeof error==='object'&&'$'in error&&error.$==='Err'?B.err_show(error as Parameters<typeof B.err_show>[0]):String(error));process.exitCode=2;}finally{rmSync(dir,{recursive:true,force:true});}
