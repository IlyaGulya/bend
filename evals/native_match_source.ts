/** Source-only Bend 0.37 match cutover. Authentic parser Body/binder identities
 * drive producer/continuation extraction; native body_flatten remains unchanged.
 * Constructor local initializers are passed once to a parameter-owned continuation;
 * nested matches own defs. Plain variable lets remain in their original scope.
 * No references, rows or terminal checks are cut.
 */
import * as B from '../bend2/bend.ts';
import {sourceOracle, type SourceOracleResult} from './bootstrap_source_oracle.ts';
import {SourceDeclarations} from './parser_full_declarations.ts';
import {renderBody} from './parser_full_body_render.ts';
import {lexicalBodyCaptures} from './parser_full_lexical_body_capture.ts';
import {LexicalTypes, freeBinderIds, type Binding} from './parser_full_type_env.ts';
import type {ParserParameter, ParserSignature} from './parser_full_graph.ts';

export type NativeMatchExtraction = {owner:string; helper:string; kind:'local'|'match'; captures:number[]; producers:number};
/** Native HOAS/indexed resolution retains binder identities and resolves only
 * unbound Var alternatives, exactly as the existing readParserGraph seam. */
function resolvedSourceBody(body:B.Body, vars:readonly B.PVar[]):B.Body{
  let fresh=0;
  function highest(value:unknown):void{
    if(!value||typeof value!=='object')return;
    for(const[key,child]of Object.entries(value))if(key!=='s'){
      if(key==='i'){
        for(const id of Array.isArray(child)?child:[child])if(typeof id==='number')fresh=Math.max(fresh,id+1);
      }else highest(child);
    }
  }
  highest(body);highest(vars);
  function bind(patterns:readonly B.Patt[],input:B.Env):B.Env{
    let env=input;
    function pattern(value:B.Patt):void{
      if(value.$==='PVar')env=B.list_set(env,value.i,B.Var(value.k,value.i));
      else value.x.forEach(pattern);
    }
    patterns.forEach(pattern);return env;
  }
  function visit(node:B.Body,env:B.Env):B.Body{
    if(node.$==='Local')return {...node,v:node.v.map(value=>B.term_lower(B.term_higher(value,env),fresh)),f:visit(node.f,bind(node.k,env))};
    if(node.$==='Match')return {...node,e:node.e.map(value=>B.term_lower(B.term_higher(value,env),fresh)),r:node.r.map(row=>({...row,f:visit(row.f,bind(row.p,env))}))};
    return B.term_lower(B.term_higher(node,env),fresh);
  }
  return visit(body,bind(vars,null));
}
export async function normalizeNativeMatchSource(file:string, source:string) {
  const oracle=await sourceOracle(file,source);
  if(!oracle.accepted){
    const error=oracle.error;
    const diagnostic=error&&typeof error==='object'&&'$'in error&&error.$==='Err'
      ?B.err_show(error as B.Err):String(error);
    throw Error('Native match source parse '+file+': '+diagnostic);
  }
  const book=oracle.normalizationBook(), declarations=new SourceDeclarations(source);
  const signatures=new Map<string,ParserSignature>();
  for(const declaration of oracle.declarations)if(declaration.body){
    let parameters=declaration.signature?.parameters, result=declaration.signature?.result;
    if(!parameters||!result){
      const prior=book.tlds[declaration.key];
      if(prior?.$!=='Def'||!declaration.vars)throw Error('Missing authentic signature '+declaration.key);
      parameters=[];
      let type=prior.T;
      for(const variable of declaration.vars){
        if(type.$!=='All')throw Error('Incomplete law signature '+declaration.key);
        parameters.push([type.q,variable.k,variable.i,B.term_lower(type.A),variable.s!]);
        type=type.B(B.Var(variable.k,variable.i));
      }
      result=B.term_lower(type);
    }
    let env:B.Env=null;
    const signatureFresh=Math.max(0,...parameters.map(parameter=>parameter[2]+1));
    parameters=parameters.map(parameter=>{
      const resolved:ParserParameter=[...parameter];
      resolved[3]=B.term_lower(B.term_higher(parameter[3],env),signatureFresh);
      env=B.list_set(env,parameter[2],B.Var(parameter[1],parameter[2]));
      return resolved;
    });
    signatures.set(declaration.key,{parameters,result:B.term_lower(B.term_higher(result,env),signatureFresh)});
  }
  const extractions:NativeMatchExtraction[]=[], replacements:{begin:number;end:number;text:string}[]=[];
  const surface={str:source,ns:'',al:Object.fromEntries(oracle.imports.filter(item=>item.alias!=='Base').map(item=>[item.alias,item.namespace]))};
  const showTerm=(term:B.LTerm,names:string[],precedence:number)=>B.term_show(term,precedence,names,surface);
  const reserved=new Set(Object.keys(book.tlds));
  for(const declaration of oracle.declarations){
    if(!declaration.body)continue;
    const owner=declaration.key, signature=signatures.get(owner)!;
    const lexical=new LexicalTypes(book,signatures);
    let fresh=0, ordinal=0;
    const seen=new WeakSet<object>();
    function reserve(value:unknown):void{
      if(!value||typeof value!=='object'||seen.has(value))return;
      seen.add(value);
      for(const[key,child]of Object.entries(value))if(key!=='s'){
        if(key==='i'){
          for(const id of Array.isArray(child)?child:[child])if(typeof id==='number')fresh=Math.max(fresh,id+1);
        }else reserve(child);
      }
    }
    reserve(declaration.body);
    for(const[, , id, type]of signature.parameters){fresh=Math.max(fresh,id+1);reserve(type);}
    reserve(signature.result);
    // Preserve already-native-valid source (especially shared datatype modules)
    // verbatim. This is the genuine native conversion, not a second matcher or
    // an exception-skipping fallback. Only its match-position restrictions are
    // repairable by introducing a source def; all other errors remain errors.
    try{
      B.body_flatten(declaration.body,declaration.vars??signature.parameters.map(([,k,i,,s])=>({$:'PVar' as const,k,i,q:B.Lone(),s})),()=>fresh++);
      continue;
    }catch(error){
      if(!error||typeof error!=='object'||!('$'in error)||error.$!=='Err'||!('exp'in error)||typeof error.exp!=='string'
        ||!error.exp.includes('a parameter or field scrutinee')&&!error.exp.includes("can't be matched"))throw error;
    }
    const originalBody=resolvedSourceBody(declaration.body,declaration.vars??signature.parameters.map(([,k,i,,s])=>({$:'PVar' as const,k,i,q:B.Lone(),s})));
    const contextual = <T>(phase:string,run:()=>T):T => {
      try { return run(); }
      catch(error) { throw Error(file+' '+owner+' '+phase+': '+(error&&typeof error==='object'&&'$'in error&&error.$==='Err'?B.err_show(error as B.Err):String(error))); }
    };
    contextual('lexical types',()=>lexical.indexBody(originalBody,signature.parameters,signature.result));
    const helpers:string[]=[];
    const entry=(body:B.Body):B.LTerm=>body.$==='Local'?body.v[0]!:body.$==='Match'?body.e[0]!:body;
    const variable=(binding:Binding):B.LTerm=>B.Var(binding.name,binding.id);
    function captures(body:B.Body, original:B.Body, provided:ReadonlySet<number>):Binding[]{
      const proxy=Object.create(lexical) as LexicalTypes;
      proxy.environmentAt=term=>lexical.environmentAt(term===entry(body)?entry(original):term);
      const found=new Map(lexicalBodyCaptures(body,proxy,{providedIds:provided}).map(binding=>[binding.id,binding]));
      const scope=lexical.environmentAt(entry(original));
      function include(id:number):void{
        if(provided.has(id)||found.has(id))return;
        const binding=scope.get(id);
        if(!binding)throw Error('Unavailable continuation type binder '+owner+': '+id);
        found.set(id,binding);
        for(const dependency of freeBinderIds(binding.type))include(dependency);
      }
      for(const id of freeBinderIds(signature.result))include(id);
      return [...found.values()];
    }
    function emit(body:B.Body, original:B.Body, bindings:Binding[], actuals:ReadonlyMap<number,B.LTerm>, leading:number[], kind:'local'|'match', producers:number):B.LTerm{
      const byId=new Map(bindings.map(binding=>[binding.id,binding])), ordered:Binding[]=[],done=new Set<number>(),active=new Set<number>();
      // A producer's dependent result type can mention an entry binder that is
      // absent from the continuation itself; keep that binder in the telescope.
      const sourceScope=lexical.environmentAt(entry(original));
      function closeType(binding:Binding):void{
        for(const id of freeBinderIds(binding.type)){
          if(byId.has(id))continue;
          const dependency=sourceScope.get(id);
          if(!dependency)throw Error('Missing producer type dependency '+owner+': '+id);
          byId.set(id,dependency);closeType(dependency);
        }
      }
      for(const binding of bindings)closeType(binding);
      function add(id:number):void{
        if(done.has(id))return;
        if(active.has(id))throw Error('Cyclic native match parameter types '+owner);
        const binding=byId.get(id);
        if(!binding)throw Error('Missing native match type parameter '+owner+': '+id);
        active.add(id);
        for(const dependency of freeBinderIds(binding.type))add(dependency);
        active.delete(id);done.add(id);ordered.push(binding);
      }
      for(const id of leading)add(id);
      for(const binding of bindings)add(binding.id);
      const helper='native_match_'+owner+'_'+ordinal++;
      if(reserved.has(helper))throw Error('Native match helper name collision '+helper);
      reserved.add(helper);
      const span=entry(body).s??entry(original).s;
      if(!span)throw Error('Missing authentic native match source span '+owner);
      const parameters:ParserParameter[]=ordered.map(binding=>[binding.quantity,binding.name,binding.id,binding.type,span]);
      const rendered=renderBody(body,parameters,{book,showTerm});
      // Helpers inherit their owner's safety contract, not a permissive shim.
      const annotations=declarations.declarations.get(owner)!.annotations.join('\n');
      helpers.push((annotations?annotations+'\n':'')+`def ${helper}(${rendered.parameters}) -> ${rendered.renderTerm(signature.result)}:\n${rendered.body}\n\n`);
      extractions.push({owner,helper,kind,captures:ordered.filter(binding=>!actuals.has(binding.id)).map(binding=>binding.id),producers});
      let call:B.LTerm=B.Ref(helper,span);
      for(const binding of ordered)call=B.App(call,actuals.get(binding.id)??variable(binding),span);
      return call;
    }
    function patternIds(pattern:B.Patt, ids:Set<number>):void{
      if(pattern.$==='PVar')ids.add(pattern.i);else pattern.x.forEach(child=>patternIds(child,ids));
    }
    function normalize(body:B.Body):B.Body{
      if(body.$==='Local'){
        const continuation=normalize(body.f);
        // A variable let is native-valid once its later matches own helper defs.
        // Keep it rather than multiplying declarations and capture arguments.
        if(body.k.every(pattern=>pattern.$==='PVar'))return {...body,f:continuation};
        const provided=new Set<number>();body.k.forEach(pattern=>patternIds(pattern,provided));
        const closed=captures(body.f,body.f,provided);
        const actuals=new Map<number,B.LTerm>();
        const produced=body.v.map((value,index):Binding=>{
          const pattern=body.k[index]!, id=pattern.$==='PVar'?pattern.i:fresh++;
          const quantity=pattern.$==='PVar'?B.quant_dem(body.q,pattern.q):body.q;
          actuals.set(id,value);
          return {id,name:pattern.$==='PVar'?pattern.k:'producer_'+id,type:lexical.typeOf(value),quantity};
        });
        let helperBody=continuation;
        // Variable lets become formals directly; destructures match that formal.
        for(let index=body.k.length-1;index>=0;index--)if(body.k[index]!.$==='PCtr')helperBody={ $:'Match',e:[variable(produced[index]!)],r:[{p:[body.k[index]!],f:helperBody}],s:body.v[index]!.s };
        return emit(helperBody,body,[...produced,...closed],actuals,produced.map(binding=>binding.id),'local',produced.length);
      }
      if(body.$==='Match'){
        const actuals=new Map<number,B.LTerm>(), produced:Binding[]=[];
        const expressions=body.e.map((expression,index)=>{
          if(expression.$==='Var')return expression;
          const id=fresh++, quantity=body.r.reduce((q,row)=>row.p[index]!.$==='PVar'?B.quant_join(q,row.p[index]!.q):q,B.Lone());
          const binding:Binding={id,name:'scrutinee_'+id,type:lexical.typeOf(expression),quantity};
          produced.push(binding);actuals.set(id,expression);return variable(binding);
        });
        const rewritten:B.Match={...body,e:expressions};
        const closed=captures(rewritten,body,new Set(produced.map(binding=>binding.id)));
        const helperBody:B.Match={...rewritten,r:body.r.map(row=>({...row,f:normalize(row.f)}))};
        return emit(helperBody,body,[...produced,...closed],actuals,expressions.flatMap(freeBinderIds),'match',produced.length);
      }
      return body;
    }
    const body=contextual('factoring',()=>normalize(originalBody));
    if(!helpers.length)continue;
    const rendered=renderBody(body,signature.parameters,{book,showTerm});
    const association=declarations.declarations.get(owner)!;
    // Law-completing definitions retain their canonical law/signature spelling.
    const header=declaration.completesLaw?`def ${owner}(${signature.parameters.map(parameter=>rendered.binderMap.get(parameter[2])!).join(', ')}):`
      :`def ${owner}(${rendered.parameters}) -> ${rendered.renderTerm(signature.result)}:`;
    replacements.push({begin:association.start-association.prefix.length,end:association.end,
      text:helpers.join('')+declarations.emit(owner,header+'\n'+rendered.body+'\n\n')});
  }
  let normalized=source;
  for(const replacement of replacements.sort((a,b)=>b.begin-a.begin))normalized=normalized.slice(0,replacement.begin)+replacement.text+normalized.slice(replacement.end);
  return {source:normalized,oracle,extractions};
}

/** Binding-aware closure over authentic raw source terms, including captures,
 * callbacks and all match rows. Imports are represented by their owned modules. */
export function nativeSourceClosure(oracle:SourceOracleResult,root:string):Set<string>{
  const bodies=new Map(oracle.declarations.filter(item=>item.body).map(item=>[item.key,item.body!]));
  const included=new Set<string>();
  function visit(name:string):void{
    if(included.has(name))return;
    const body=bodies.get(name);if(!body)throw Error('Missing canonical closure definition '+name);
    included.add(name);
    const seen=new WeakSet<object>();
    function references(value:unknown):void{
      if(!value||typeof value!=='object'||seen.has(value))return;
      seen.add(value);
      if('$'in value&&value.$==='Ref'&&'k'in value&&typeof value.k==='string'&&bodies.has(value.k))visit(value.k);
      for(const[key,child]of Object.entries(value))if(key!=='s')if(Array.isArray(child))child.forEach(references);else references(child);
    }
    references(resolvedSourceBody(body,oracle.declarations.find(item=>item.key===name)!.vars??[]));
  }
  visit(root);return included;
}
