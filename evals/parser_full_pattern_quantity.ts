import type {Body,LTerm,Patt} from '../bend2/bend.ts';
import type {ParserParameter} from './parser_full_graph.ts';
import {freeBinderIds,MissingType,type LexicalTypes} from './parser_full_type_env.ts';
import {runtimeUses} from './parser_full_consumer.ts';

export type QuantityHelper={name:string;body:Body;parameters:ParserParameter[];result:LTerm};
export type QuantityLift={body:Body;helpers:QuantityHelper[];lifted:{binderId:number;name:string;helper:string;runtimeUses:number;type:LTerm}[]};

/** A copied Sigma tail depends on the inferred codomain application. Its explicit
 * type belongs on a helper parameter, not on the dependent pattern projection.
 * Direct constructor fields and the first Sigma field retain their quantities.
 */
export function hasPatternQuantityBoundary(body:Body):boolean {
 function pattern(node:Patt,parent?:Extract<Patt,{$:'PCtr'}>,field?:number):boolean {
  if(node.$==='PVar')return node.q.$==='Many'&&parent?.k==='Tuple'&&field===1;
  return node.x.some((child,index)=>pattern(child,node,index));
 }
 if(body.$==='Match')return body.r.some(row=>row.p.some(p=>pattern(p))||hasPatternQuantityBoundary(row.f));
 if(body.$==='Local')return body.k.some(p=>pattern(p))||hasPatternQuantityBoundary(body.f);
 return false;
}

export function liftPatternQuantities(body:Body,parameters:readonly ParserParameter[],result:LTerm,types:LexicalTypes,prefix:string):QuantityLift {
 const helpers:QuantityHelper[]=[],lifted:QuantityLift['lifted']=[];
 const span=parameters[0]?.[4]??{file:{str:'',ns:'',al:{}},beg:0,end:0};
 function patternIds(node:Patt):number[]{return node.$==='PVar'?[node.i]:node.x.flatMap(patternIds);}
 function freeBody(node:Body):Set<number>{
  if(node.$!=='Local'&&node.$!=='Match')return new Set(freeBinderIds(node));
  const free=new Set<number>();
  if(node.$==='Local'){
   const bound=new Set(node.k.flatMap(patternIds));
   for(const id of freeBody(node.f))if(!bound.has(id))free.add(id);
   for(const value of node.v)for(const id of freeBinderIds(value))free.add(id);
  }else{
   for(const value of node.e)for(const id of freeBinderIds(value))free.add(id);
   for(const row of node.r){
    const bound=new Set(row.p.flatMap(patternIds));
    for(const id of freeBody(row.f))if(!bound.has(id))free.add(id);
   }
  }
  return free;
 }
 function entry(node:Body):LTerm {
  if(node.$!=='Local'&&node.$!=='Match')return node;
  const expression=node.$==='Local'?node.v[0]:node.e[0];
  if(!expression)throw Error('Quantity boundary lacks an indexed scope expression');
  return expression;
 }
 function linearPatterns(patterns:readonly Patt[]){
  const targets:Extract<Patt,{$:'PVar'}>[]=[];
  function visit(node:Patt,parent?:Extract<Patt,{$:'PCtr'}>,field?:number):Patt{
   if(node.$==='PCtr')return {...node,x:node.x.map((child,index)=>visit(child,node,index))};
   if(node.q.$==='Many'&&parent?.k==='Tuple'&&field===1){
    targets.push(node);
    return {...node,q:{$:'Lone'}};
   }
   return node;
  }
  return {patterns:patterns.map(p=>visit(p)),targets};
 }
 function boundary(continuation:Body,original:Body,targets:Extract<Patt,{$:'PVar'}>[]):Body{
  const environment=types.environmentAt(entry(original)),captures=freeBody(continuation);
  // Keep the declared quantity obligation even when the field is unused.
  for(const target of targets)captures.add(target.i);
  for(const id of freeBinderIds(result))captures.add(id);
  const ordered:number[]=[],visiting=new Set<number>(),visited=new Set<number>();
  function include(id:number){
   if(visited.has(id))return;
   if(visiting.has(id))throw new MissingType('cyclic quantity-helper type dependency',undefined,id);
   const binding=environment.get(id);
   if(!binding)throw new MissingType('quantity-helper capture has no lexical binding',undefined,id);
   visiting.add(id);
   for(const dependency of freeBinderIds(binding.type))include(dependency);
   visiting.delete(id);visited.add(id);ordered.push(id);
  }
  for(const id of captures)include(id);
  const targetIds=new Set(targets.map(target=>target.i));
  const helper=prefix+'_'+helpers.length;
  const helperParameters:ParserParameter[]=ordered.map(id=>{
   const binding=environment.get(id)!;
   return [targetIds.has(id)?{$:'Many'}:binding.quantity,binding.name,id,binding.type,span];
  });
  helpers.push({name:helper,body:continuation,parameters:helperParameters,result});
  const uses=runtimeUses(continuation);
  for(const target of targets)lifted.push({binderId:target.i,name:target.k,helper,
   runtimeUses:uses.get(target.i)??0,type:environment.get(target.i)!.type});
  let call:LTerm={$:'Ref',k:helper};
  for(const id of ordered)call={$:'App',f:call,x:{$:'Var',i:id,k:environment.get(id)!.name}};
  return call;
 }
 function visit(node:Body):Body{
  if(node.$!=='Local'&&node.$!=='Match')return node;
  if(node.$==='Local'){
   const {patterns,targets}=linearPatterns(node.k),continuation=visit(node.f);
   return {...node,k:patterns,f:targets.length?boundary(continuation,node.f,targets):continuation};
  }
  return {...node,r:node.r.map(row=>{
   const {patterns,targets}=linearPatterns(row.p),continuation=visit(row.f);
   return {...row,p:patterns,f:targets.length?boundary(continuation,row.f,targets):continuation};
  })};
 }
 const transformed=visit(body);
 return {body:transformed,helpers,lifted};
}
