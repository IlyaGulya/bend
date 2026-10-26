import * as B from '../bend2/bend.ts';
import * as Comp from '../bend2/comp.ts';
import {extractOperatorKeyShape} from './operator_key_shape_source.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {mkdtempSync,writeFileSync,rmSync} from 'node:fs';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {createHash} from 'node:crypto';
await guardHeavyGate(import.meta.path,{label:'Actual compiled operator source helper smoke'});
const original=await Bun.file('bend2/selfhost/parser.bend').text(),start=original.indexOf('def map_operator_key('),end=original.indexOf('\ndef ',start)+1,small='import Base\n\n'+original.slice(start,end),prepared=await extractOperatorKeyShape(small),dir=mkdtempSync(join(tmpdir(),'bend-operator-smoke-'));
try{
 const path=join(dir,'main.bend');writeFileSync(path,prepared.source);const book=B.book_nil();await B.book_load(book,path,'',new Map());B.book_valid(book);if(book.hols||book.open)throw Error('Unfilled smoke book');
 const code=Comp.js_lib(book,true,{roots:['map_operator_key'],exports:['map_operator_key']}),js=join(dir,'operator.js');writeFileSync(js,code);const compiled=(await import(js)).default;
 const literals=prepared.audit.rows.filter(r=>r.mapped).map(r=>JSON.parse(r.pattern) as string),keys=[...literals,'','add','.addx','..add','.ADD','unknown','λ','.is_l'];
 const results=[];for(const namespace of ['U32','', 'α'])for(const key of keys){const expected=literals.includes(key)?namespace+key:key,actual=compiled.map_operator_key(namespace,key);if(actual!==expected)throw Error(JSON.stringify({namespace,key,expected,actual}));results.push({namespace,key,expected,actual});}
 writeFileSync('checkpoints/operator-equality-smoke.json',JSON.stringify({status:'PASS',backend:'actual compiled JS',source:prepared.source,sourceSha256:prepared.audit.transformedSha256,jsSha256:createHash('sha256').update(code).digest('hex'),nativeEvents:book.order.length,results},null,2)+'\n');console.log('PASS actual compiled operator equality smoke '+results.length+' cases');
}catch(error){console.error(error&&typeof error==='object'&&'$'in error&&error.$==='Err'?B.err_show(error as Parameters<typeof B.err_show>[0]):String(error));process.exitCode=2;}finally{rmSync(dir,{recursive:true,force:true});}
