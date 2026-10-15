#!/usr/bin/env bun
/** Validate the full-order prefix once, then use book_valid's incremental API.
 * The original order remains visible to its complete last-declaration pass.
 * A boundary exception only stops the subsequent checking pass between defs.
 */
import {resolve} from 'node:path';
import {book_load,book_nil,book_valid,err_show,type Book,type Err} from '../bend2/bend.ts';
import {guardHeavyGate} from './heavy_gate.ts';

await guardHeavyGate(import.meta.path,{label:'parser-prefix-checker'});

const target=process.argv[2];
if(!target)throw Error('Usage: bun evals/parser_full_target_check.ts <declaration> [candidate.bend]');
const file=resolve(process.argv[3]??resolve(import.meta.dir,'../bend2/selfhost/parser_full_generated_fuel.bend'));
const book=book_nil();
await book_load(book,file,'',new Map());
const order=book.order,index=order.lastIndexOf(target);
if(index<0)throw Error('Missing target declaration '+target);
const boundary=Symbol('validated checking boundary');
function through(book:Book,stopBefore:number,done:number){
 const reads=new Map<number,number>();
 book.order=new Proxy(order,{get(array,key,receiver){
  if(typeof key==='string'&&/^\d+$/.test(key)){
   const position=Number(key),count=(reads.get(position)??0)+1;
   reads.set(position,count);
   if(count===2&&position===stopBefore)throw boundary;
  }
  return Reflect.get(array,key,receiver);
 }});
 try{book_valid(book,done);}catch(error){if(error!==boundary)throw error;}
 finally{book.order=order;}
}
try{
 const start=performance.now();
 through(book,index,0);
 console.log(JSON.stringify({phase:'prefix-validated',target,index,prefixSeconds:(performance.now()-start)/1000,checker:'unchanged book_valid(book, 0)',completeOrderRetained:true}));
 through(book,index+1,index);
 console.log(JSON.stringify({status:'PASS',target,index,checker:'unchanged book_valid(book, validatedPrefixLength)'}));
}catch(error){
 if(error&&typeof error==='object'&&'$' in error&&error.$==='Err')console.error(err_show(error as Err));
 else console.error(error);
 process.exitCode=1;
}
