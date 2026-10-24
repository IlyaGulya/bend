/** Binding-aware canonical module composition for the typed CPS boundary.
 * Only explicitly selected modules move into this boundary. Other modules keep
 * their canonical identity and ordinary native admission; this is not checking.
 */
import {createHash} from 'node:crypto';
import {readFileSync, realpathSync} from 'node:fs';
import {dirname, relative, resolve} from 'node:path';
import * as B from '../bend2/bend.ts';
import {sourceOracle} from './bootstrap_source_oracle.ts';
import {SourceDeclarations} from './parser_full_declarations.ts';
import {renderBody} from './parser_full_body_render.ts';
import type {ParserParameter} from './parser_full_graph.ts';

export type CPSProviderClosure = readonly string[];
export type CPSCompositionProof = {
  providers:string[]; sourceSha256:string;
  sources:{canonical:string;canonicalSha256:string;declarationNames:string[];symbols:Record<string,string>}[];
  declarations:{source:string;canonicalName:string;name:string;kind:string;canonicalDeclarationSha256:string;composedDeclarationSha256:string}[];
  inputs:Record<string,string>;
};
const sha = (text:string) => createHash('sha256').update(text).digest('hex');
export async function composeCanonicalCPSSource(canonical:string, providers:CPSProviderClosure) {
  try {
  const paths=[canonical,...[...providers].sort()];
  const files=paths.map(path=>realpathSync(path));
  if(new Set(files).size!==files.length)throw Error('Duplicate canonical CPS source');
  const inputs=new Map<string,string>();
  const units=[];
  for(let index=0;index<paths.length;index++){
    const path=paths[index]!, file=files[index]!, source=readFileSync(path,'utf8');
    inputs.set(path,source);
    const oracle=await sourceOracle(path,source,{recordInputs:true});
    if(!oracle.accepted)throw Error('Canonical CPS source parse '+path+': '+(oracle.error&&typeof oracle.error==='object'&&'$'in oracle.error&&oracle.error.$==='Err'?B.err_show(oracle.error as B.Err):String(oracle.error)));
    for(const row of oracle.inputFiles){
      const text=readFileSync(row.file,'utf8');
      if(sha(text)!==row.sha256)throw Error('Canonical CPS parser input changed '+row.file);
      const prior=inputs.get(row.file);
      if(prior!==undefined&&prior!==text)throw Error('Mixed canonical CPS parser inputs '+row.file);
      inputs.set(row.file,text);
    }
    units.push({path,file,source,oracle,association:new SourceDeclarations(source),symbols:new Map<string,string>()});
  }
  const reserved=new Set<string>();
  // Root public names stay stable. Provider names are deterministic and checked
  // against every declaration/constructor, not merely against other functions.
  for(const declaration of units[0]!.oracle.declarations){
    reserved.add(declaration.key);
    for(const constructor of declaration.constructors??[])reserved.add(constructor.key);
  }
  for(let index=0;index<units.length;index++){
    const unit=units[index]!;
    for(const declaration of unit.oracle.declarations){
      for(const key of [declaration.key,...(declaration.constructors??[]).map(row=>row.key)]){
        if(unit.symbols.has(key))continue; // A type and its constructor may share a name.
        let name=index===0?key:'cps_provider_'+index+'_'+key;
        if(index!==0){while(reserved.has(name))name+='_';reserved.add(name);}
        unit.symbols.set(key,name);
      }
    }
  }
  const external=new Map<string,{alias:string;path:string}>(), aliases=new Set<string>();
  const namespaceMaps=new Map<typeof units[number],Map<string,typeof units[number]|string>>();
  for(const unit of units){
    const namespaces=new Map<string,typeof units[number]|string>();
    namespaceMaps.set(unit,namespaces);
    for(const imported of unit.oracle.imports){
      if(imported.alias==='Base')continue;
      if(!imported.resolved)throw Error('Missing canonical import identity '+unit.path+': '+imported.path);
      const file=realpathSync(imported.resolved), selected=units.find(row=>row.file===file);
      if(selected){namespaces.set(imported.namespace,selected);continue;}
      let entry=external.get(file);
      if(!entry){
        let alias=imported.alias;
        while(aliases.has(alias)||reserved.has(alias))alias+='_';
        aliases.add(alias);
        let path=relative(dirname(resolve(canonical)),file).split('\\').join('/');
        if(!path.startsWith('.'))path='./'+path;
        entry={alias,path};external.set(file,entry);
      }
      namespaces.set(imported.namespace,entry.alias);
    }
  }
  const typeRows:{name:string;text:string;dependencies:Set<string>}[]=[], definitionRows:string[]=[];
  const ownership:{source:string;canonicalName:string;name:string;kind:string;canonicalDeclarationSha256:string;composedDeclarationSha256:string}[]=[];
  for(const unit of units){
    const namespaces=namespaceMaps.get(unit)!;
    function symbol(key:string):string{
      const colon=key.indexOf(':');
      if(colon<0)return unit.symbols.get(key)??key;
      const namespace=key.slice(0,colon), local=key.slice(colon+1), target=namespaces.get(namespace);
      if(typeof target==='string')return target+':'+local;
      if(target){const name=target.symbols.get(local);if(!name)throw Error('Unknown composed provider symbol '+key);return name;}
      throw Error('Unauthenticated composition namespace '+unit.path+': '+key);
    }
    // Only semantic global-symbol nodes are renamed. Binder/field names, literal
    // strings and source comments are never searched or replaced for spellings.
    function remap<T>(value:T):T{
      if(!value||typeof value!=='object')return value;
      if(Array.isArray(value))return value.map(remap) as T;
      const node=value as Record<string,unknown>, out:Record<string,unknown>={};
      for(const[key,child]of Object.entries(node))out[key]=key==='s'?child:remap(child);
      if(['Ref','Ctr','ADT','PCtr','Mat'].includes(String(node.$)))out.k=symbol(node.k as string);
      if(node.$==='ADT')out.r=(node.r as string[]).map(symbol);
      return out as T;
    }
    const surface={str:'',ns:'',al:Object.fromEntries([...external.values()].map(row=>[row.alias,row.alias]))};
    const showTerm=(term:B.LTerm,names:string[],precedence:number)=>B.term_show(remap(term),precedence,names,surface);
    // Resolve parser alternatives by lexical binder identity, without the
    // HOAS/native bridge. term_higher also beta-reduces applications, which is
    // not a source-composition operation.
    type Scope=ReadonlyMap<number,B.LTerm>;
    function resolveTerm(term:B.LTerm,scope:Scope):B.LTerm{
      function bind(id:number,key:string):Scope{
        const inner=new Map(scope);inner.set(id,B.Var(key,id));return inner;
      }
      switch(term.$){
        case 'Var': {
          const binding=scope.get(term.i);
          if(binding)return {...binding,s:term.s};
          if(term.i<0)return {...term};
          if(term.v){
            if(term.v.$!=='Ref')throw Error('Unexpected non-reference parser alternative '+unit.path+': '+term.k);
            return {...term.v,s:term.s};
          }
          return B.Ref(term.k,term.s);
        }
        case 'All': return {...term,A:resolveTerm(term.A,scope),B:resolveTerm(term.B,bind(term.i,term.k))};
        case 'Lam': return {...term,f:resolveTerm(term.f,bind(term.i,term.k))};
        case 'Let': {
          const inner=new Map(scope);
          term.i.forEach((id,index)=>inner.set(id,B.Var(term.k[index]!,id)));
          return {...term,v:term.v.map(value=>resolveTerm(value,scope)),f:resolveTerm(term.f,inner)};
        }
        case 'Sub': {
          const inner=new Map(scope);inner.set(term.i,resolveTerm(B.patt_term(term.v),scope));
          return resolveTerm(term.f,inner);
        }
        case 'Typ': return {...term,g:resolveTerm(term.g,scope)};
        case 'Min': return {...term,a:resolveTerm(term.a,scope),b:resolveTerm(term.b,scope)};
        case 'App': return {...term,f:resolveTerm(term.f,scope),x:resolveTerm(term.x,scope)};
        case 'ADT': case 'Ctr': return {...term,x:term.x.map(value=>resolveTerm(value,scope))};
        case 'Mat': return {...term,h:resolveTerm(term.h,scope),m:resolveTerm(term.m,scope)};
        case 'Eql': return {...term,a:resolveTerm(term.a,scope),b:resolveTerm(term.b,scope),T:resolveTerm(term.T,scope)};
        case 'Rwt': return {...term,e:resolveTerm(term.e,scope),p:resolveTerm(term.p,scope),f:resolveTerm(term.f,scope)};
        case 'Ann': return {...term,x:resolveTerm(term.x,scope),T:resolveTerm(term.T,scope)};
        case 'Ref': case 'Lit': case 'Qnt': case 'Qua': case 'Efq': case 'Rfl': case 'Hol': return {...term};
        default: {const exhaustive:never=term;throw Error('Unsupported canonical term '+String(exhaustive));}
      }
    }
    function resolveBody(node:B.Body,scope:Scope):B.Body{
      function bind(patterns:readonly B.Patt[]):Scope{
        const inner=new Map(scope);
        function add(pattern:B.Patt):void{if(pattern.$==='PVar')inner.set(pattern.i,B.Var(pattern.k,pattern.i));else pattern.x.forEach(add);}
        patterns.forEach(add);return inner;
      }
      if(node.$==='Local')return {...node,v:node.v.map(value=>resolveTerm(value,scope)),f:resolveBody(node.f,bind(node.k))};
      if(node.$==='Match')return {...node,e:node.e.map(value=>resolveTerm(value,scope)),r:node.r.map(row=>({...row,f:resolveBody(row.f,bind(row.p))}))};
      return resolveTerm(node,scope);
    }
    for(const declaration of unit.oracle.declarations){
      const name=unit.symbols.get(declaration.key)!, association=unit.association.declarations.get(declaration.key);
      if(!association)throw Error('Missing canonical declaration association '+declaration.key);
      let rendered:string;
      if(declaration.kind==='type'){
        const parameters=declaration.parameters??[], dependencies=new Set<string>();
        function telescope(rows:ParserParameter[],initial:Scope=new Map(),initialNames:string[]=[]){
          const env=new Map(initial), names=[...initialNames], texts:string[]=[];
          const term=(value:B.LTerm)=>{
            const resolved=resolveTerm(value,env);
            function refs(node:unknown):void{
              if(!node||typeof node!=='object')return;
              if('$'in node&&['Ref','ADT'].includes(String(node.$))&&'k'in node)dependencies.add(symbol(node.k as string));
              for(const[key,child]of Object.entries(node))if(key!=='s')if(Array.isArray(child))child.forEach(refs);else refs(child);
            }
            refs(resolved);return showTerm(resolved,names,-1);
          };
          for(const[q,key,id,type]of rows){
            texts.push(type.$==='Qnt'?key:B.quant_show(q)+key+': '+term(type));
            env.set(id,B.Var(key,names.length));names.push(key);
          }
          return {env,names,text:texts.join(', '),term};
        }
        const tele=telescope(parameters);
        if(!declaration.kindTerm)throw Error('Missing canonical datatype kind '+name);
        rendered='type '+name+(parameters.length?'<'+tele.text+'>':'')+' is '+tele.term(declaration.kindTerm)+':\n'
          +(declaration.constructors??[]).map(ctor=>'  '+unit.symbols.get(ctor.key)+'{'+telescope(ctor.fields,tele.env,tele.names).text+'}').join('\n')+'\n\n';
        rendered=unit.association.emit(declaration.key,rendered);
        typeRows.push({name,text:rendered,dependencies});
      }else if(declaration.kind==='def'&&declaration.body&&declaration.signature?.parameters&&declaration.signature.result&&!declaration.completesLaw&&!declaration.template){
        const env=new Map<number,B.LTerm>();
        const parameters=declaration.signature.parameters.map(parameter=>{
          const resolved:ParserParameter=[...parameter];
          resolved[3]=resolveTerm(parameter[3],env);
          env.set(parameter[2],B.Var(parameter[1],parameter[2]));return resolved;
        });
        const result=resolveTerm(declaration.signature.result,env);
        const body=renderBody(resolveBody(declaration.body,env),parameters,{showTerm,book:unit.oracle.normalizationBook()});
        rendered=unit.association.emit(declaration.key,'def '+name+'('+body.parameters+') -> '+body.renderTerm(result)+':\n'+body.body+'\n\n');
        definitionRows.push(rendered);
      }else throw Error('Unsupported canonical CPS composition declaration '+unit.path+': '+declaration.kind+' '+declaration.key);
      ownership.push({source:unit.path,canonicalName:declaration.key,name,kind:declaration.kind,
        canonicalDeclarationSha256:sha(unit.source.slice(association.start-association.prefix.length,association.end)),composedDeclarationSha256:sha(rendered)});
    }
  }
  // A datatype is a declaration, not code: the native book declares ADTs whole
  // up front and its types may name each other in any order. Emit composed
  // datatypes in source order so genuinely mutual tree types (Layout/LayArm,
  // Fill/FormArm/Nest) are legal instead of being rejected by an artificial
  // dependency order.
  const ordered:string[]=typeRows.map(row=>row.text);
  const source='import Base\n'+[...external.values()].map(row=>'import '+row.path+' as '+row.alias+'\n').join('')+'\n'+ordered.join('')+definitionRows.join('');
  const proof:CPSCompositionProof={providers:[...providers].sort(),sourceSha256:sha(source),
    sources:units.map(unit=>({canonical:unit.path,canonicalSha256:sha(unit.source),declarationNames:unit.oracle.declarations.map(row=>row.key),symbols:Object.fromEntries(unit.symbols)})),
    declarations:ownership,inputs:Object.fromEntries([...inputs].map(([path,text])=>[path,sha(text)]))};
  for(const[path,text]of inputs)if(readFileSync(path,'utf8')!==text)throw Error('Canonical CPS input changed during composition '+path);
  return {source,proof,inputs};
  } catch(error) {
    if(error&&typeof error==='object'&&'$'in error&&error.$==='Err')
      throw Error('Canonical CPS composition '+canonical+': '+B.err_show(error as B.Err));
    throw error;
  }
}
