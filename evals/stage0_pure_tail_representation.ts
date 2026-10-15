import * as B from '../bend2/bend.ts';
import {Observation} from './stage0_trailing_suffix_sharing.ts';
type Syntax=B.LTerm|B.HTerm;
function measure(root:Syntax,names:readonly string[],stage:string){
  const observation=new Observation(true);observation.visit(root);
  const declarations=new Map<string,Syntax[]>();
  const references=new Map<string,number>();
  const kinds={Sub:0,Lam:0,Let:0,App:0,Mat:0};
  const known=new Set(names);
  for(const node of observation.termNodes){
    const term=node as Syntax;
    if(term.$==='Sub'||term.$==='Lam'||term.$==='Let'||term.$==='App'||term.$==='Mat')kinds[term.$]++;
    if(term.$==='Var'&&known.has(term.k))references.set(term.k,(references.get(term.k)??0)+1);
    if(term.$==='Let')for(let j=0;j<term.k.length;j++)if(known.has(term.k[j])){
      if(term.q[j].$!=='Lone')throw Error('Residual function binder is not Lone');
      const name=term.k[j],values=declarations.get(name);
      if(values)values.push(term.v[j]);else declarations.set(name,[term.v[j]]);
    }
  }
  const residuals=names.map(name=>{
    const definitions=declarations.get(name)??[];
    const roots=new Set<Syntax>(),union=new Set<object>();
    let lambdas=0;
    for(const value of definitions){
      let body=value;
      if(body.$==='Ann')body=body.x;
      while(body.$==='Lam'){
        lambdas++;const next=observation.bodies.get(body);
        if(!next)throw Error('Residual lambda body was not materialized');body=next;
      }
      roots.add(body);for(const node of observation.descendants(body))union.add(node);
    }
    return {name,declarations:definitions.length,bodyCopies:roots.size,parameterLambdas:lambdas,
      body:observation.counts(union),uniqueReferenceNodes:references.get(name)??0};
  });
  return {stage,...observation.counts(observation.descendants(root)),...kinds,
    observedCallbacks:observation.observedCallbacks.size,residuals};
}
export function measurePureTailRepresentation(term:B.LTerm,names:readonly string[]){
  if(names.length===0)throw Error('Real adapter representation fixture has no residual');
  const initial=measure(term,names,'constructed-lower');
  const higher=B.term_higher(term),high=measure(higher,names,'materialized-higher');
  const lower=B.term_lower(higher),low=measure(lower,names,'roundtrip-lower');
  const stages=[initial,high,low,measure(B.term_higher(lower),names,'final-materialized-higher')];
  return {stages,pass:stages.every(s=>s.residuals.every(r=>r.declarations===1&&r.bodyCopies===1&&r.parameterLambdas>0)),
    counting:'Existing Observation fully materializes Lam/All/Let callbacks with bound Vars. Converter calls are independent of observation caches; no opaque closure counts as sharing proof. Each compiler-issued residual name must have exactly one Let declaration and one body root at every stage.'};
}

/** Static path proof for the named C{resource}/True affine native fixture. */
export function proveAffinePrefixPaths(term:B.LTerm,names:readonly string[]){
  const higher=B.term_higher(term),observation=new Observation(true);observation.visit(higher);
  if(higher.$!=='Let')throw Error('Affine fixture expected outer residual Let');
  const split=observation.bodies.get(higher);
  if(split?.$!=='Mat'||split.k!=='C'||split.h.$!=='Lam'||split.h.q?.$!=='Lone')throw Error('Affine C branch must bind its resource field One');
  const later=observation.bodies.get(split.h);
  if(later?.$!=='Mat'||later.k!=='True')throw Error('Affine fixture expected later Bool test');
  const known=new Set(names);
  function count(root:Syntax){
    let residualReferences=0,reconstructedC=0;
    for(const node of observation.descendants(root))if(observation.termNodes.has(node)){
      const syntax=node as Syntax;
      if(syntax.$==='Var'&&known.has(syntax.k))residualReferences++;
      if(syntax.$==='Ctr'&&syntax.k==='C')reconstructedC++;
    }
    return {residualReferences,reconstructedC};
  }
  const success=count(later.h),failure=count(later.m);
  if(success.residualReferences!==0||success.reconstructedC!==0||failure.residualReferences!==1||failure.reconstructedC!==1)throw Error('Affine prefix reconstruction/call path invariant failed');
  return {fieldQuantity:'Lone',success,failure,nativeOwnershipProof:'Native book_valid checks actual One field usage and rejects same-path duplicate transfer; C/True returns 7 while C/False reconstructs and returns 17.'};
}
