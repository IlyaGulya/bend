import {expect,test} from 'bun:test';
import * as B from '../bend2/bend.ts';
import {semanticCases,invalidAffineMatrix} from './parser_full_match_factor_fixtures.ts';
import {mkdtemp,writeFile,rm} from 'node:fs/promises';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
async function load(source:string){const directory=await mkdtemp(join(tmpdir(),'bend-stage0-match-'));try{const path=join(directory,'main.bend');await writeFile(path,source);const book=B.book_nil();await B.book_load(book,path,'',new Map());return book;}finally{await rm(directory,{recursive:true,force:true});}}
function run(book:B.Book,a:string,b:string){
  const p:B.Parse={book,dir:tmpdir()+'/',str:`matrix(${a}, ${b})`,pos:0,stk:[],frs:0,ns:'',al:{}};
  let value=B.term_wnf(book,B.term_higher(B.parse_term(p))),prefix=0;
  while(value.$==='Ctr'&&value.k==='Succ'&&value.x.length===1){prefix++;value=B.term_wnf(book,value.x[0]);}
  if(value.$==='Lit'&&value.k==='Nat')return prefix+value.v;
  if(value.$==='Ctr'&&value.k==='Zero'&&value.x.length===0)return prefix;
  throw Error('Expected Nat result');
}
for(const item of semanticCases)test(`stage0 ${item.name} preserves ordered native match results`,async()=>{const book=await load(item.source);B.book_valid(book);for(const[a,b,expected]of item.inputs)expect(run(book,a,b)).toBe(expected);},30000);
test('stage0 still rejects contraction of affine input',async()=>{const book=await load(invalidAffineMatrix);let accepted=true;try{B.book_valid(book);}catch(error){if(!error||typeof error!=='object'||!('$'in error)||error.$!=='Err')throw error;accepted=false;}expect(accepted).toBe(false);});
