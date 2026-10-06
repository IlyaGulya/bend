import {parse_term,term_higher,term_lower,term_show,term_unapply,type Book,type LTerm,type Parse} from '../bend2/bend.ts';

export type Product = {type:string;left?:Product;right?:Product};

/** Shared generated payload layout for values, requests and continuations. */
export class ProductTypes {
 constructor(readonly book:Book,readonly aliases:Record<string,string>={},readonly show:(term:LTerm)=>string=term_show) {}
 private readonly cache=new Map<string,Product>();
 parse(source:string):Product {
  const cached=this.cache.get(source);
  if(cached)return cached;
  const parser:Parse={book:this.book,dir:'',str:source,pos:0,sc:{stk:[],frs:0},ns:'',al:this.aliases,os:[],inst:null,ts:[],lv:0};
  const result=this.fromTerm(term_lower(term_higher(parse_term(parser))));
  if(source.slice(parser.pos).trim())throw Error('Unparsed generated payload type: '+source);
  this.cache.set(source,result);
  return result;
 }
 fromTerm(term:LTerm):Product {
  if(term.$==='Ann')return this.fromTerm(term.x);
  const [head,args]=term_unapply(term);
  if(head.$==='Ref'&&head.k==='Pair'&&args.length===2){
   const left=this.fromTerm(args[0]!),right=this.fromTerm(args[1]!);
   return {type:`(${left.type} & ${right.type})`,left,right};
  }
  return {type:this.show(term)};
 }
}

export function productFields(name:string,tree:Product):{name:string;type:string}[]{
 return tree.left&&tree.right?[...productFields(name+'_0',tree.left),...productFields(name+'_1',tree.right)]:[{name,type:tree.type}];
}

export function productValue(name:string,tree:Product):string {
 return tree.left&&tree.right?`(${productValue(name+'_0',tree.left)}, ${productValue(name+'_1',tree.right)})`:name;
}
