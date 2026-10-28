import * as B from '../bend2/bend.ts';
import * as Comp from '../bend2/comp.ts';
import {guardHeavyGate} from './heavy_gate.ts';
import {writeFileSync} from 'node:fs';
await guardHeavyGate(import.meta.path,{label:'Native canonical parser fast generated execution probe, zero validation exclusions'});
try{
 const book=B.book_nil();await B.book_load(book,process.cwd()+'/bend2/selfhost/parser.bend','',new Map());console.log(JSON.stringify({stage:'loaded',declarations:book.order.length}));B.book_valid(book);
 if(book.hols||book.open)throw Error('Incomplete native parser validation');
 const code=Comp.js_lib(book,true,{roots:['parse'],exports:['parse']});writeFileSync('checkpoints/bootstrap-canonical-native-fast.js',code);
 console.log(JSON.stringify({status:'PASS',declarations:book.order.length,bytes:Buffer.byteLength(code),proof:'Exact canonical parser source through unchanged stage0 compiler; zero validation exclusions'}));
}catch(error){console.error(error&&typeof error==='object'&&'$'in error&&error.$==='Err'?B.err_show(error as Parameters<typeof B.err_show>[0]):String(error));process.exitCode=2;}
