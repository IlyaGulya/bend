#!/usr/bin/env bun
/** Observe declaration boundaries without changing or skipping checker work. */
import {resolve} from 'node:path';
import {book_load,book_nil,book_valid,err_show,type Err} from '../bend2/bend.ts';
import {guardHeavyGate} from './heavy_gate.ts';

await guardHeavyGate(import.meta.path,{label:'parser full candidate check'});

const path=resolve(import.meta.dir,'../bend2/selfhost/parser_full_generated_fuel.bend');
const book=book_nil();
await book_load(book,path,'',new Map());
const reads=new Map<number,number>();
book.order=new Proxy(book.order,{get(target,key,receiver){
 if(typeof key==='string'&&/^\d+$/.test(key)){
  const index=Number(key),count=(reads.get(index)??0)+1;
  reads.set(index,count);
  if(count===2)console.log(JSON.stringify({checking:index,name:target[index]}));
 }
 return Reflect.get(target,key,receiver);
}});
try{book_valid(book);console.log(JSON.stringify({status:'PASS',declarations:book.order.length}));}
catch(error){
 if(error&&typeof error==='object'&&'$' in error&&error.$==='Err')console.error(err_show(error as Err));
 else console.error(error);
 process.exitCode=1;
}
