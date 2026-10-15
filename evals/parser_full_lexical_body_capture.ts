import type {Body,LTerm,Patt,Quant} from '../bend2/bend.ts';
import {freeBinderIds,termChildren,LexicalTypes} from './parser_full_type_env.ts';
import type {Binding} from './parser_full_type_env.ts';
export type CaptureOptions={providedIds?:ReadonlySet<number>;ignoredRanges?:readonly {beg:number;end:number}[]};
export function captureQuantityPrefix(quantity:Quant):string{
 return quantity.$==='Many'?'+':quantity.$==='None'?'-':'';
}
/** Free source binders of an extracted Body, closed over parameter type
 * dependencies. Identity is lexical binder ID, never a spelling allowlist. */
export function lexicalBodyCaptures(body:Body,lexical:LexicalTypes,options:CaptureOptions={}):Binding[]{
 const first=body.$==='Match'?body.e[0]:body.$==='Local'?body.v[0]:body;
 if(!first)throw Error('Extracted body has no entry expression');
 const entry=lexical.environmentAt(first),captures=new Map<number,Binding>();
 const provided=options.providedIds??new Set<number>();
 function ignored(term:LTerm){return term.s!==undefined&&(options.ignoredRanges??[]).some(range=>term.s!.beg>=range.beg&&term.s!.end<=range.end);}
 function patternIds(pattern:Patt,out:Set<number>){if(pattern.$==='PVar'){if(pattern.k!=='_')out.add(pattern.i);}else for(const child of pattern.x)patternIds(child,out);}
 function expression(term:LTerm,bound:ReadonlySet<number>){
  if(ignored(term))return;
  if(term.$==='Var'){
   if(bound.has(term.i)||provided.has(term.i))return;
   const binding=entry.get(term.i);
   if(!binding)throw Error('Free extracted binder is outside entry scope: '+term.i);
   captures.set(binding.id,binding);return;
  }
  if(term.$==='Lam'){expression(term.f,new Set([...bound,term.i]));return;}
  if(term.$==='All'){expression(term.A,bound);expression(term.B,new Set([...bound,term.i]));return;}
  if(term.$==='Let'){for(const value of term.v)expression(value,bound);expression(term.f,new Set([...bound,...term.i]));return;}
  if(term.$==='Sub'){for(const child of termChildren(term).slice(0,-1))expression(child,bound);expression(term.f,new Set([...bound,term.i]));return;}
  for(const child of termChildren(term))expression(child,bound);
 }
 function visit(node:Body,bound:ReadonlySet<number>){
  if(node.$!=='Local'&&node.$!=='Match'){expression(node,bound);return;}
  if(node.$==='Local'){const inner=new Set(bound);for(let i=0;i<node.v.length;i++){expression(node.v[i],inner);patternIds(node.k[i],inner);}visit(node.f,inner);return;}
  for(const term of node.e)expression(term,bound);
  for(const row of node.r){const inner=new Set(bound);for(const pattern of row.p)patternIds(pattern,inner);visit(row.f,inner);}
 }
 visit(body,new Set());
 // Capturing x:T also requires any source binder in T, even when that binder
 // appears only in a parameter type and not in the extracted executable body.
 function dependencies(binding:Binding){return freeBinderIds(binding.type).filter(id=>!provided.has(id));}
 function close(binding:Binding){for(const id of dependencies(binding)){if(captures.has(id))continue;const dependency=entry.get(id);if(!dependency)throw Error('Capture type depends on an unavailable binder: '+id);captures.set(id,dependency);close(dependency);}}
 for(const binding of [...captures.values()])close(binding);
 const ordered:Binding[]=[],done=new Set<number>(),active=new Set<number>();
 function emit(id:number){if(done.has(id))return;if(active.has(id))throw Error('Cyclic extracted capture types');active.add(id);const binding=captures.get(id)!;for(const dependency of dependencies(binding).sort((a,b)=>a-b))if(captures.has(dependency))emit(dependency);active.delete(id);done.add(id);ordered.push(binding);}
 // The linear source flattener consumes formals in order. A row's initial
 // scrutinees must precede captures scrutinized only in nested matches.
 // Type dependencies still precede each selected formal.
 for(const id of body.$==='Match'?body.e.flatMap(freeBinderIds):[])if(captures.has(id))emit(id);
 for(const id of [...captures.keys()].sort((a,b)=>a-b))emit(id);
 return ordered;
}
