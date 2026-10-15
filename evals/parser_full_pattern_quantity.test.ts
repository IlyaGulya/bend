import {test,expect} from 'bun:test';
import {randomUUID} from 'node:crypto';
import {writeFileSync,rmSync} from 'node:fs';
import {resolve} from 'node:path';
import {book_load,book_nil,book_valid,err_show,type Err} from '../bend2/bend.ts';
import {js_lib} from '../bend2/comp.ts';
import {readParserGraph} from './parser_full_graph.ts';
import {LexicalTypes} from './parser_full_type_env.ts';
import {renderBody} from './parser_full_body_render.ts';
import {SourceDeclarations} from './parser_full_declarations.ts';
import {hasPatternQuantityBoundary,liftPatternQuantities} from './parser_full_pattern_quantity.ts';

async function compile(source:string){
 const graph=await readParserGraph(source),types=new LexicalTypes(graph.parserBook,graph.signatures);
 const declarations=new SourceDeclarations(source),emitted:string[]=[];
 for(const name of graph.definitions){
  const signature=graph.signatures.get(name)!,body=graph.bodies.get(name)!;
  if(!hasPatternQuantityBoundary(body)){emitted.push(declarations.emit(name));continue;}
  types.indexBody(body,signature.parameters,signature.result);
  const lifted=liftPatternQuantities(body,signature.parameters,signature.result,types,'quantity_'+name);
  for(const helper of lifted.helpers){
   const printed=renderBody(helper.body,helper.parameters,{book:graph.parserBook});
   emitted.push(`def ${helper.name}(${printed.parameters}) -> ${printed.renderTerm(helper.result)}:\n${printed.body}`);
  }
  const printed=renderBody(lifted.body,signature.parameters,{book:graph.parserBook});
  emitted.push(declarations.emit(name,`def ${name}(${printed.parameters}) -> ${printed.renderTerm(signature.result)}:\n${printed.body}`));
 }
 const prefix=source.slice(0,source.indexOf('def '));
 const path=resolve(import.meta.dir,'../bend2/selfhost/.quantity-lifting-'+randomUUID()+'.bend');
 writeFileSync(path,prefix+emitted.join('\n\n')+'\n');
 try{
  const book=book_nil();
  try{await book_load(book,path,'',new Map());book_valid(book);}
  catch(error){if(error&&typeof error==='object'&&'$' in error&&error.$==='Err')throw Error(err_show(error as Err));throw error;}
  const javascript=js_lib(book,true,{roots:['inspect'],exports:['inspect']});
  return (await import('data:text/javascript;base64,'+Buffer.from(javascript).toString('base64'))).default;
 }finally{rmSync(path,{force:true});}
}
const pair=(fst:unknown,snd:unknown)=>({$:'Tuple',fst,snd});
const empty={$:'Nil'},one={$:'Con',head:4,tail:empty};

test('a copied nested Sigma field crosses a typed boundary and retains real duplication behavior',async()=>{
 const compiled=await compile(`import Base
def inspect(x: ((Nat & List<&2, Nat>) & Bool)) -> Bool:
  match x:
    case ((head, +items), flag): Bool.and(List.is_empty(&2, Nat, items), List.is_empty(&2, Nat, items))
`);
 expect(compiled.inspect(pair(pair(3,empty),true))).toBe(true);
 expect(compiled.inspect(pair(pair(3,one),true))).toBe(false);
});

test('a deeper product boundary preserves the non-copied flag',async()=>{
 const compiled=await compile(`import Base
def inspect(x: (((Nat & List<&2, Nat>) & Bool) & Nat)) -> Bool:
  match x:
    case (((head, +items), flag), tag): Bool.and(flag, Bool.and(List.is_empty(&2, Nat, items), List.is_empty(&2, Nat, items)))
`);
 expect(compiled.inspect(pair(pair(pair(3,empty),true),4))).toBe(true);
 expect(compiled.inspect(pair(pair(pair(3,empty),false),4))).toBe(false);
 expect(compiled.inspect(pair(pair(pair(3,one),true),4))).toBe(false);
});

test('two copied fields retain independent list values and quantities',async()=>{
 const compiled=await compile(`import Base
def inspect(x: ((List<&2, Nat> & List<&2, Nat>) & Bool)) -> Bool:
  match x:
    case ((+first, +second), flag): Bool.and(Bool.and(List.is_empty(&2, Nat, first), List.is_empty(&2, Nat, first)), Bool.and(List.is_empty(&2, Nat, second), List.is_empty(&2, Nat, second)))
`);
 expect(compiled.inspect(pair(pair(empty,empty),true))).toBe(true);
 expect(compiled.inspect(pair(pair(one,empty),true))).toBe(false);
 expect(compiled.inspect(pair(pair(empty,one),true))).toBe(false);
});

test('the lifted copied field does not duplicate its affine sibling',async()=>{
 const compiled=await compile(`import Base
def inspect(x: ((List<&1, Nat> & List<&2, Nat>) & Bool)) -> Bool:
  match x:
    case ((sibling, +items), flag): Bool.and(List.is_empty(&1, Nat, sibling), Bool.and(List.is_empty(&2, Nat, items), List.is_empty(&2, Nat, items)))
`);
 expect(compiled.inspect(pair(pair(empty,empty),true))).toBe(true);
 expect(compiled.inspect(pair(pair(one,empty),true))).toBe(false);
 expect(compiled.inspect(pair(pair(empty,one),true))).toBe(false);
});

test('once-used product fields need no copied quantity',async()=>{
 const compiled=await compile(`import Base
def inspect(x: ((Nat & List<&2, Nat>) & Bool)) -> Bool:
  match x:
    case ((head, items), flag): List.is_empty(&2, Nat, items)
`);
 expect(compiled.inspect(pair(pair(3,empty),true))).toBe(true);
 expect(compiled.inspect(pair(pair(3,one),true))).toBe(false);
});

test('direct typed constructor fields retain their already-valid quantity boundary',async()=>{
 const compiled=await compile(`import Base
type Bag is Data:
  Bag{items: List<&2, Nat>, spare: Nat}
def inspect(x: Bag) -> Bool:
  match x:
    case Bag{+items, spare}: Bool.and(List.is_empty(&2, Nat, items), List.is_empty(&2, Nat, items))
`);
 expect(compiled.inspect({$:'Bag',items:empty,spare:3})).toBe(true);
 expect(compiled.inspect({$:'Bag',items:one,spare:3})).toBe(false);
});

test('local product destructuring also transfers the copied field once',async()=>{
 const compiled=await compile(`import Base
def inspect(x: ((Nat & List<&2, Nat>) & Bool)) -> Bool:
  ((head, +items), flag) = x
  Bool.and(List.is_empty(&2, Nat, items), List.is_empty(&2, Nat, items))
`);
 expect(compiled.inspect(pair(pair(3,empty),true))).toBe(true);
 expect(compiled.inspect(pair(pair(3,one),true))).toBe(false);
});

test('a nested continuation preserves branch-local binder identities',async()=>{
 const compiled=await compile(`import Base
def inspect(x: ((Nat & List<&2, Nat>) & Bool)) -> Bool:
  match x:
    case ((head, +items), flag):
      match flag:
        case True{}:
          result = List.is_empty(&2, Nat, items)
          Bool.and(result, List.is_empty(&2, Nat, items))
        case False{}: False{}
`);
 expect(compiled.inspect(pair(pair(3,empty),true))).toBe(true);
 expect(compiled.inspect(pair(pair(3,one),true))).toBe(false);
 expect(compiled.inspect(pair(pair(3,empty),false))).toBe(false);
});

test('helper type dependencies stay erased and precede the copied generic list',async()=>{
 const compiled=await compile(`import Base
def inspect(-A: Data, x: ((Nat & List<&2, A>) & Bool)) -> Bool:
  match x:
    case ((head, +items), flag): Bool.and(List.is_empty(&2, A, items), List.is_empty(&2, A, items))
`);
 expect(compiled.inspect(pair(pair(3,empty),true))).toBe(true);
 expect(compiled.inspect(pair(pair(3,one),true))).toBe(false);
});

test('an unused copied affine field still has to satisfy the explicit quantity domain',async()=>{
 await expect(compile(`import Base
def inspect(x: ((Nat & List<&1, Nat>) & Bool)) -> Bool:
  match x:
    case ((head, +items), flag): flag
`)).rejects.toThrow('Data');
});
