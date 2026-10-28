import * as B from '../bend2/bend.ts';
import * as Comp from '../bend2/comp.ts';
import {extractSymbolPairShape} from './symbol_pair_shape_source.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {mkdtempSync,writeFileSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {createHash} from 'node:crypto';
await guardHeavyGate(import.meta.path,{label:'Actual compiled symbol pair equality smoke'});
const dir=mkdtempSync(join(tmpdir(),'bend-symbol-pair-smoke-'));
try{
 const source=await Bun.file('bend2/selfhost/parser.bend').text(),typeStart=source.indexOf('type SymbolPairClass is Data:'),typeEnd=source.indexOf('type SymbolTripleClass',typeStart),start=source.indexOf('def multi_symbol_2('),end=source.indexOf('\ndef ',start)+1,prepared=await extractSymbolPairShape('import Base\n\n'+source.slice(typeStart,typeEnd)+source.slice(start,end));
 const bend=join(dir,'main.bend');writeFileSync(bend,prepared.source);const book=B.book_nil();await B.book_load(book,bend,'',new Map());B.book_valid(book);if(book.hols||book.open)throw Error('Unfilled symbol smoke book');const code=Comp.js_lib(book,true,{roots:['multi_symbol_2'],exports:['multi_symbol_2']}),js=join(dir,'symbols.js');writeFileSync(js,code);const compiled=(await import(js)).default;
 const literals=prepared.audit.rows.slice(0,13).map(r=>JSON.parse(r.pattern) as string),inputs=[...literals,'','=','x','=>x','<= ','&&&','x=>','😺x','λξ','\u0000x','→','\n','>','<<x'],results=[];
 for(const text of inputs){const expected=literals.includes(text)?{$:'SymbolPairMerged',pair:text}:{$:'SymbolPairUnmerged',left:[...text][0]??''},actual=compiled.multi_symbol_2(text);if(JSON.stringify(actual)!==JSON.stringify(expected))throw Error(JSON.stringify({text,expected,actual}));results.push({text,expected,actual});}
 writeFileSync('checkpoints/symbol-pair-equality-smoke.json',JSON.stringify({status:'PASS',backend:'actual compiled JS',source:prepared.source,sourceSha256:prepared.audit.transformedSha256,jsSha256:createHash('sha256').update(code).digest('hex'),nativeEvents:book.order.length,results},null,2)+'\n');console.log('PASS actual compiled symbol pair '+results.length+' cases');
}catch(error){console.error(error&&typeof error==='object'&&'$'in error&&error.$==='Err'?B.err_show(error as Parameters<typeof B.err_show>[0]):String(error));process.exitCode=2;}finally{rmSync(dir,{recursive:true,force:true});}
