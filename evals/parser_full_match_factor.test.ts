import {expect,test} from 'bun:test';
import * as B from '../bend2/bend.ts';
import {readParserGraph} from './parser_full_graph.ts';
import {renderBody} from './parser_full_body_render.ts';
import {factorMatches} from './parser_full_match_factor.ts';
import {semanticCases,invalidAffineMatrix} from './parser_full_match_factor_fixtures.ts';
import {mkdtemp,writeFile,rm} from 'node:fs/promises';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
async function native(source:string,factored:boolean){
  let emitted=source;
  if(factored){const graph=await readParserGraph(source),signature=graph.signatures.get('matrix')!;const result=factorMatches(graph.bodies.get('matrix')!,{minimumRows:2,minimumFreshId:Math.max(...signature.parameters.map(p=>p[2]))+1});const rendered=renderBody(result.body,signature.parameters,{book:graph.parserBook});emitted=source.slice(0,source.indexOf('def matrix('))+`def matrix(${rendered.parameters}) -> Nat:\n${rendered.body}\n`;}
  const directory=await mkdtemp(join(tmpdir(),'bend-factor-test-'));try{const path=join(directory,'main.bend');await writeFile(path,emitted);const book=B.book_nil();await B.book_load(book,path,'',new Map());return book;}finally{await rm(directory,{recursive:true,force:true});}
}
function run(book:B.Book,a:string,b:string):number {
  const p:B.Parse={book,dir:tmpdir()+'/',str:`matrix(${a}, ${b})`,pos:0,stk:[],frs:0,ns:'',al:{}};
  let value=B.term_wnf(book,B.term_higher(B.parse_term(p))),prefix=0;
  // A compact Nat can also be the tail of an evaluated Succ constructor.
  while(value.$==='Ctr'&&value.k==='Succ'&&value.x.length===1){prefix++;value=B.term_wnf(book,value.x[0]);}
  if(value.$==='Lit'&&value.k==='Nat')return prefix+value.v;
  if(value.$==='Ctr'&&value.k==='Zero'&&value.x.length===0)return prefix;
  throw Error('Expected a Nat result');
}
for(const item of semanticCases){
  test(`native factoring preserves ${item.name} priority, bindings and values`,async()=>{
    const results:number[][]=[];
    for(const factored of [false,true]){
      const book=await native(item.source,factored);
      B.book_valid(book);
      const values=item.inputs.map(([a,b])=>run(book,a,b));
      expect(values).toEqual(item.inputs.map(([, ,expected])=>expected));
      results.push(values);
    }
    expect(results[1]).toEqual(results[0]);
  },30000);
}
test('native factoring still rejects contraction of an affine resource',async()=>{
  for(const factored of[false,true]){
    const book=await native(invalidAffineMatrix,factored);
    let rejected=false;
    try{B.book_valid(book);}
    catch(error){
      if(!error||typeof error!=='object'||!('$'in error)||error.$!=='Err')throw error;
      expect(B.err_show(error as B.Err)).toContain('consumed more than once');
      rejected=true;
    }
    expect(rejected).toBe(true);
  }
});
