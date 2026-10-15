import {expect,test} from 'bun:test';
import {randomUUID} from 'node:crypto';
import {writeFileSync,rmSync} from 'node:fs';
import {resolve} from 'node:path';
import {book_load,book_nil,book_valid,err_show,type Err} from '../bend2/bend.ts';
import {js_lib} from '../bend2/comp.ts';
import {term_show} from '../bend2/bend.ts';
import {readParserGraph} from './parser_full_graph.ts';
import {ProductTypes,productFields,productValue} from './parser_full_product.ts';

const graph=await readParserGraph('import Base\ntype Item is Data:\n  Item{}\ndef identity(value: Nat) -> Nat:\n  value\n');
const types=new ProductTypes(graph.parserBook,{},term_show);

test('internal Pair applications produce the same payload layout as surface products',()=>{
 expect(productFields('value',types.parse('Pair(Pair(Nat, Bool), String)'))).toEqual([
  {name:'value_0_0',type:'Nat'},
  {name:'value_0_1',type:'Bool'},
  {name:'value_1',type:'String'},
 ]);
 expect(productValue('value',types.parse('Pair(Pair(Nat, Bool), String)'))).toBe('((value_0_0, value_0_1), value_1)');
 expect(productFields('value',types.parse('(Nat & Bool) & String'))).toEqual(productFields('value',types.parse('Pair(Pair(Nat, Bool), String)')));
});


test('simple product spellings preserve the same two-field layout',()=>{
 const expected=[{name:'pair_0',type:'Nat'},{name:'pair_1',type:'Bool'}];
 for(const spelling of ['Nat & Bool','(Nat & Bool)','Pair(Nat, Bool)']){
  expect(productFields('pair',types.parse(spelling))).toEqual(expected);
  expect(types.parse(spelling).type).toBe('(Nat & Bool)');
 }
});

test('right-nested products retain their association and reconstruction',()=>{
 const expected=[{name:'value_0',type:'Nat'},{name:'value_1_0',type:'Bool'},{name:'value_1_1',type:'String'}];
 for(const spelling of ['Nat & (Bool & String)','Pair(Nat, Pair(Bool, String))']){
  expect(productFields('value',types.parse(spelling))).toEqual(expected);
  expect(productValue('value',types.parse(spelling))).toBe('(value_0, (value_1_0, value_1_1))');
 }
});

test('list quantity and element types survive nested payload decomposition',()=>{
 const expected=[{name:'value_0_0',type:'List<&2, Item>'},{name:'value_0_1',type:'Bool'},{name:'value_1',type:'List<&2, Nat>'}];
 for(const spelling of ['(List<&2, Item> & Bool) & List<&2, Nat>','Pair(Pair(List<&2, Item>, Bool), List<&2, Nat>)']){
  expect(productFields('value',types.parse(spelling))).toEqual(expected);
 }
 expect(productFields('items',types.parse('List<&2, Item>'))).toEqual([{name:'items',type:'List<&2, Item>'}]);
});

test('generated flattened Data payload checks and reconstructs its semantic product',async()=>{
 const layout=types.parse('Pair(Pair(Nat, Bool), List<&2, Item>)');
 const fields=productFields('value',layout);
 const path=resolve(import.meta.dir,'../bend2/selfhost/.product-payload-'+randomUUID()+'.bend');
 writeFileSync(path,`import Base
type Item is Data:
  Item{}
type Payload is Data:
  Payload{${fields.map(f=>f.name+': '+f.type).join(', ')}}
def roundtrip(payload: Payload) -> ${layout.type}:
  match payload:
    case Payload{${fields.map(f=>f.name).join(', ')}}:
      ${productValue('value',layout)}
`);
 try{
  const book=book_nil();
  await book_load(book,path,'',new Map());
  try{book_valid(book);}catch(error){if(error&&typeof error==='object'&&'$' in error&&error.$==='Err')throw Error(err_show(error as Err));throw error;}
  const javascript=js_lib(book,true,{roots:['roundtrip'],exports:['roundtrip']});
  const compiled=(await import('data:text/javascript;base64,'+Buffer.from(javascript).toString('base64'))).default;
  const items={$:'Con',head:{$:'Item'},tail:{$:'Nil'}};
  expect(compiled.roundtrip({$:'Payload',value_0_0:7,value_0_1:true,value_1:items})).toEqual({$:'Tuple',fst:{$:'Tuple',fst:7,snd:true},snd:items});
 }finally{rmSync(path,{force:true});}
});