import {expect,test} from 'bun:test';
import {randomUUID} from 'node:crypto';
import {writeFileSync,rmSync} from 'node:fs';
import {resolve} from 'node:path';
import {book_load,book_nil,book_valid,err_show,type Err} from '../bend2/bend.ts';
import {SourceDeclarations} from './parser_full_declarations.ts';
import {readParserGraph} from './parser_full_graph.ts';

async function checked(source:string){
 const path=resolve(import.meta.dir,'../bend2/selfhost/.declaration-metadata-'+randomUUID()+'.bend');
 writeFileSync(path,source);
 try{
  const book=book_nil();
  try{
   await book_load(book,path,'',new Map());
   book_valid(book);
  }catch(error){
   if(error&&typeof error==='object'&&'$' in error&&error.$==='Err')throw Error(err_show(error as Err));
   throw error;
  }
  return book;
 }finally{rmSync(path,{force:true});}
}

test('reordering keeps a non-decreasing helper annotation on its own definition',async()=>{
 const declarations=new SourceDeclarations(`import Base
def plain() -> Nat:
  3n
@unsafe
def revisit(value: Nat) -> Nat:
  revisit(value)
`);
 const book=await checked('import Base\n'+declarations.emit('revisit')+'\n\n'+declarations.emit('plain'));
 expect(book.tlds.revisit.$==='Def'&&book.tlds.revisit.u).toBe(true);
 expect(book.tlds.plain.$==='Def'&&book.tlds.plain.u).not.toBe(true);
});

test('unannotated definitions stay checked after signature and body transformation',async()=>{
 const declarations=new SourceDeclarations('def identity(value: Nat) -> Nat:\n  value\n');
 const book=await checked('import Base\n'+declarations.emit('identity','def lifted_identity(value: Bool) -> Bool:\n  value'));
 expect(book.tlds.lifted_identity.$==='Def'&&book.tlds.lifted_identity.u).not.toBe(true);
 await expect(checked('import Base\n'+declarations.emit('identity','def lifted_identity(value: Bool) -> Bool:\n  lifted_identity(value)'))).rejects.toThrow('a decreasing self-call');
});

test('multiple independently annotated definitions retain their own exemption',async()=>{
 const declarations=new SourceDeclarations(`@unsafe
def revisit(value: Nat) -> Nat:
  revisit(value)
@unsafe
def repeat(value: Bool) -> Bool:
  repeat(value)
def plain() -> Nat:
  7n
`);
 const book=await checked('import Base\n'+['repeat','plain','revisit'].map(name=>declarations.emit(name)).join('\n\n'));
 expect(book.tlds.revisit.$==='Def'&&book.tlds.revisit.u).toBe(true);
 expect(book.tlds.repeat.$==='Def'&&book.tlds.repeat.u).toBe(true);
 expect(book.tlds.plain.$==='Def'&&book.tlds.plain.u).not.toBe(true);
});

test('lifting and subsequent replacement preserve metadata despite changed name, signature and body',async()=>{
 const declarations=new SourceDeclarations('@unsafe\n# Metadata belongs to the next definition.\n\ndef revisit(value: Nat) -> Nat:\n  revisit(value)\n');
 const transformed=declarations.emit('revisit','def lifted_revisit(value: Bool) -> Bool:\n  lifted_revisit(value)');
 const book=await checked('import Base\n'+declarations.emit('revisit',transformed));
 expect(book.tlds.lifted_revisit.$==='Def'&&book.tlds.lifted_revisit.u).toBe(true);
});

test('an adjacent annotation never exempts an unrelated non-decreasing helper',async()=>{
 const declarations=new SourceDeclarations(`def ordinary(value: Nat) -> Nat:
  ordinary(value)
@unsafe
def exempt(value: Nat) -> Nat:
  exempt(value)
`);
 await expect(checked('import Base\n'+declarations.emit('exempt')+'\n\n'+declarations.emit('ordinary'))).rejects.toThrow('a decreasing self-call');
});

test('AST dependency ordering moves metadata with the definition, not the source neighbor',async()=>{
 const source=`import Base
def entry(value: Nat) -> Nat:
  revisit(plain(value))
@unsafe
def revisit(value: Nat) -> Nat:
  revisit(value)
def plain(value: Nat) -> Nat:
  value
`;
 const declarations=new SourceDeclarations(source),graph=await readParserGraph(source);
 const ordered:string[]=[],visited=new Set<string>();
 function visit(name:string){
  if(visited.has(name))return;
  visited.add(name);
  for(const dependency of graph.edges[name]??[])if(dependency!==name)visit(dependency);
  ordered.push(declarations.emit(name));
 }
 visit('entry');
 const book=await checked('import Base\n'+ordered.join('\n\n'));
 expect(book.tlds.revisit.$==='Def'&&book.tlds.revisit.u).toBe(true);
 expect(book.tlds.entry.$==='Def'&&book.tlds.entry.u).not.toBe(true);
 expect(book.tlds.plain.$==='Def'&&book.tlds.plain.u).not.toBe(true);
});

test('incompatible declaration transformation reports metadata instead of dropping it',()=>{
 const declarations=new SourceDeclarations('@unsafe\ndef revisit(value: Nat) -> Nat:\n  revisit(value)\n');
 expect(()=>declarations.emit('revisit','type Revisit is Data:\n  Revisit{}')).toThrow('Incompatible declaration metadata');
});
