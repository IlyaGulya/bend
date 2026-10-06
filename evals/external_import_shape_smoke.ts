import * as B from '../bend2/bend.ts';
import * as Comp from '../bend2/comp.ts';
import {extractExternalImportShape} from './external_import_shape_source.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {mkdtempSync,writeFileSync,rmSync} from 'node:fs';
import {resolve,join} from 'node:path';
import {createHash} from 'node:crypto';
await guardHeavyGate(import.meta.path,{label:'Actual compiled shrinking external-import worker smoke'});
const source=await Bun.file('bend2/selfhost/parser.bend').text(),start=source.indexOf('def strip_quotes_reversed('),end=source.indexOf('def parse_external_imports('),small='import Base\nimport ./lexer.bend as Lexer\n\n'+source.slice(start,end),dir=mkdtempSync(resolve('bend2/selfhost/.external-import-smoke-'));
const newline=['NewlineToken','\n'],marker=['NameToken','def'],keyword=['NameToken','import'],pathA=['StringToken','"a"'],pathB=['StringToken','"b"'],bad=['NameToken','bad'];
const fixtures=[
 {name:'empty',tokens:[],paths:[],rest:[],ok:true},
 {name:'newline-only',tokens:[newline],paths:[],rest:[],ok:true},
 {name:'other',tokens:[marker],paths:[],rest:[marker],ok:true},
 {name:'newline-preserved-with-other',tokens:[newline,marker],paths:[],rest:[newline,marker],ok:true},
 {name:'one-import',tokens:[keyword,pathA,marker],paths:['a'],rest:[marker],ok:true},
 {name:'two-imports-newlines',tokens:[keyword,pathA,newline,keyword,pathB,newline,marker],paths:['a','b'],rest:[newline,marker],ok:true},
 {name:'invalid-path',tokens:[keyword,bad,marker],paths:[],rest:[bad,marker],ok:false},
 {name:'missing-path',tokens:[keyword],paths:[],rest:[],ok:false},
 {name:'trailing-newline',tokens:[keyword,pathA,newline],paths:['a'],rest:[],ok:true},
 {name:'kind-priority',tokens:[['SymbolToken','import'],pathA],paths:[],rest:[['SymbolToken','import'],pathA],ok:true},
 {name:'keyword-near-miss',tokens:[['NameToken','imports'],pathA],paths:[],rest:[['NameToken','imports'],pathA],ok:true},
 {name:'newline-not-a-path',tokens:[keyword,newline,marker],paths:[],rest:[newline,marker],ok:false},
 {name:'valid-then-invalid',tokens:[keyword,pathA,newline,keyword,bad],paths:['a'],rest:[bad],ok:false},
 {name:'empty-path',tokens:[keyword,['StringToken','""']],paths:[''],rest:[],ok:true},
 {name:'unicode-path',tokens:[keyword,['StringToken','"λ"']],paths:['λ'],rest:[],ok:true},
 {name:'existing-accumulator',tokens:[keyword,pathA],acc:['prior','older'],paths:['older','prior','a'],rest:[],ok:true}
];
try{
 const prepared=await extractExternalImportShape(small+'def smoke_end() -> Nat:\n  0n\n'),loadedSource=prepared.source.replace('import ./lexer.bend as Lexer','import ../lexer.bend as Lexer');
 const bend=join(dir,'main.bend');writeFileSync(bend,loadedSource);const book=B.book_nil();await B.book_load(book,bend,'',new Map());B.book_valid(book);if(book.hols||book.open)throw Error('Unfilled smoke book');const code=Comp.js_lib(book,['parse_external_imports_scan'],['parse_external_imports_scan']),js=join(dir,'imports.js');writeFileSync(js,code);
 const execute=`const compiled=(await import(${JSON.stringify(js)})).default;const nil={$:'Nil'};const list=xs=>xs.reduceRight((tail,head)=>({$:'Con',head,tail}),nil);const array=xs=>{const out=[];while(xs.$==='Con'){out.push(xs.head);xs=xs.tail;}if(xs.$!=='Nil')throw Error('Invalid compiled list');return out;};const fixtures=${JSON.stringify(fixtures)};const results=fixtures.map(f=>{const tokens=list(f.tokens.map(([kind,text],i)=>({$:'TokenInfo',kind:{$:kind},text,beg:BigInt(i),end:BigInt(i+1),line:0n,col:0n})));const result=compiled.parse_external_imports_scan(tokens,tokens,list(f.acc??[]));const actual={paths:array(result.fst.fst),rest:array(result.fst.snd).map(t=>[t.kind.$,t.text]),ok:result.snd};const expected={paths:f.paths,rest:f.rest,ok:f.ok};if(JSON.stringify(actual)!==JSON.stringify(expected))throw Error(JSON.stringify({name:f.name,actual,expected}));return{name:f.name,actual,expected};});console.log(JSON.stringify(results));`;
 const child=Bun.spawn([process.execPath,'-e',execute],{stdout:'pipe',stderr:'pipe'}),[out,err,exit]=await Promise.all([new Response(child.stdout).text(),new Response(child.stderr).text(),child.exited]);if(exit)throw Error('Actual compiled import worker failed: '+err);const results=JSON.parse(out);
 writeFileSync('checkpoints/external-import-worker-smoke.json',JSON.stringify({status:'PASS',backend:'actual compiled JS',source:loadedSource,sourceSha256:createHash('sha256').update(loadedSource).digest('hex'),transformedSourceSha256:prepared.audit.transformedSha256,importPathRedirectOnly:true,jsSha256:createHash('sha256').update(code).digest('hex'),nativeEvents:book.order.length,results},null,2)+'\n');console.log('PASS actual compiled external-import worker '+results.length+' cases');
}catch(error){console.error(error&&typeof error==='object'&&'$'in error&&error.$==='Err'?B.err_show(error as Parameters<typeof B.err_show>[0]):String(error));process.exitCode=2;}finally{rmSync(dir,{recursive:true,force:true});}
