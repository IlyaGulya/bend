import * as B from '../bend2/bend.ts';
import {readParserGraph,type ParserParameter} from './parser_full_graph.ts';
import {suffixFixtures} from './stage0_trailing_suffix_fixtures.ts';
import {checkFixture,compileResidual,Observation} from './stage0_trailing_suffix_sharing.ts';
import {runNativeSuffixWitness} from './stage0_trailing_suffix_native.ts';

type Syntax=B.LTerm|B.HTerm;
type Stage='constructed-lower'|'higher'|'roundtrip-lower'|'final-higher';
function requireShape(condition:boolean,message:string):asserts condition {
  if(!condition)throw Error('Explicit binding witness: '+message);
}

// A function is Type, not Data. Two mutually exclusive uses join to Lone:
// no function contraction, no Many closure, no quantity promotion is needed.
function residualValue(body:B.Match,parameters:ParserParameter[]):B.LTerm {
  const flag=10001,later=10002;
  const compiled=compileResidual(body,parameters);
  const type=():B.LTerm=>B.All(B.Lone(),'suffix_flag',10006,B.Ref('Bool'),
    B.All(B.Lone(),'suffix_later',10007,B.Ref('Bool'),B.Ref('Nat')));
  const applied=B.App(B.App(B.Ann(compiled,type()),B.Var('suffix_flag',flag)),B.Var('suffix_later',later));
  const fn:B.LTerm=B.Lam('suffix_flag',flag,B.Lam('suffix_later',later,applied,undefined,B.Lone()),undefined,B.Lone());
  return B.Ann(fn,type());
}

/** This fixed zero-field, closed suffix fixture only; not a match compiler. */
function assemble(body:B.Match,parameters:ParserParameter[],first:B.LTerm,second:B.LTerm):B.LTerm {
  const [,flag,later]=parameters;
  const replies=body.r.slice(0,2).map(row=>row.f);
  requireShape(replies[0].$==='Reply'&&replies[1].$==='Reply','literal prefix replies');
  const call=(fn:B.LTerm,flagIndex:number,laterIndex:number):B.LTerm=>
    B.App(B.App(fn,B.Var('call_flag',flagIndex)),B.Var('call_later',laterIndex));
  const prefixLater=B.Mat('True',replies[0].x,B.Lam('prefix_later',10004,replies[1].x,undefined,later[0]));
  const prefixFailure=B.Lam('prefix_flag',10003,
    B.Lam('prefix_remaining',10004,call(first,10003,10004),undefined,later[0]),undefined,flag[0]);
  const prefix=B.Mat('True',prefixLater,prefixFailure);
  const outer=B.Lam('outer_tag',10005,
    B.Lam('outer_flag',10006,B.Lam('outer_later',10007,call(second,10006,10007),undefined,later[0]),undefined,flag[0]));
  return B.Mat('C',prefix,outer);
}

function measure(root:Syntax,stage:Stage,binding:boolean){
  const observation=new Observation(true);
  observation.visit(root);
  const nodes=observation.descendants(root);
  const kinds={Lam:0,Let:0,App:0,Mat:0};
  const residualValues:Syntax[]=[];
  let callSites=0,referenceNodes=0;
  for(const node of observation.termNodes){
    const term=node as Syntax;
    if(term.$==='Lam'||term.$==='Let'||term.$==='App'||term.$==='Mat')kinds[term.$]++;
    if(term.$==='Var'&&term.k==='residual')referenceNodes++;
    if(term.$==='Let'&&term.k.length===1&&term.k[0]==='residual'){
      requireShape(binding&&term.q[0].$==='Lone'&&term.v.length===1,'one legal Lone residual Let');
      residualValues.push(term.v[0]);
    }
    if(term.$==='App'&&term.f.$==='App'){
      const fn=term.f.f;
      if(binding&&fn.$==='Var'&&fn.k==='residual')callSites++;
      if(!binding&&fn.$==='Ann'&&fn.x.$==='Lam'&&fn.x.k==='suffix_flag'){
        callSites++;residualValues.push(fn);
      }
    }
  }
  const roots:Syntax[]=[],bodyNodes=new Set<object>();
  for(const value of residualValues){
    requireShape(value.$==='Ann'&&value.x.$==='Lam'&&value.x.k==='suffix_flag','annotated residual lambda');
    const later=observation.bodies.get(value.x);
    requireShape(later?.$==='Lam'&&later.k==='suffix_later','second residual argument');
    const body=observation.bodies.get(later);
    requireShape(body!==undefined,'materialized residual body');
    roots.push(body);
    for(const node of observation.descendants(body))bodyNodes.add(node);
  }
  requireShape(callSites===2,'two mutually exclusive residual call sites');
  requireShape(residualValues.length===(binding?1:2),'binding/control residual definition count');
  const uniqueRoots=new Set(roots);
  const residualBody=observation.counts(bodyNodes);
  const oneCopy=observation.counts(observation.descendants(roots[0]));
  return {stage,...observation.counts(nodes),...kinds,
    residualBodyUniqueObjects:residualBody.graphObjects,residualBodyUniqueNodes:residualBody.termNodes,
    residualBodyCopies:uniqueRoots.size,residualNodesPerCopy:oneCopy.termNodes,
    callSites,residualReferenceSites:binding?callSites:0,uniqueResidualReferenceNodes:referenceNodes,
    observedCallbacks:observation.observedCallbacks.size};
}
function stages(lower:B.LTerm,binding:boolean){
  const constructed=measure(lower,'constructed-lower',binding);
  const higher=B.term_higher(lower);
  const high=measure(higher,'higher',binding);
  // Observation bodies are not supplied to either unchanged converter.
  const roundtrip=B.term_lower(higher);
  const low=measure(roundtrip,'roundtrip-lower',binding);
  return [constructed,high,low,measure(B.term_higher(roundtrip),'final-higher',binding)];
}

export async function runExplicitBindingSharing(){
  const fixture=suffixFixtures.find(f=>f.name==='eligible-closed');
  requireShape(fixture!==undefined,'same eligible ordered suffix fixture');
  const graph=await readParserGraph(fixture.source);
  const body=graph.bodies.get('matrix'),signature=graph.signatures.get('matrix');
  requireShape(body!==undefined&&signature!==undefined,'raw source body/signature');
  checkFixture(body,signature.parameters);
  const independent=await readParserGraph(fixture.source);
  const secondBody=independent.bodies.get('matrix'),secondSignature=independent.signatures.get('matrix');
  requireShape(secondBody!==undefined&&secondSignature!==undefined,'independent control source');
  checkFixture(secondBody,secondSignature.parameters);
  const residual=residualValue(body,signature.parameters);
  const reference1=B.Var('residual',10000),reference2=B.Var('residual',10000);
  // Binding value and call operand are deliberately separate: no raw DAG reuse.
  const bound=assemble(body,signature.parameters,reference1,reference2);
  const shared=B.Let(['residual'],[10000],[residual],bound,undefined,[B.Lone()]);
  const control=assemble(body,signature.parameters,residualValue(body,signature.parameters),residualValue(secondBody,signature.parameters));
  const sharedStages=stages(shared,true),controlStages=stages(control,false);
  const representationSurvives=sharedStages.every(s=>s.residualBodyCopies===1&&s.Let===1&&s.callSites===2)
    &&controlStages.every(s=>s.residualBodyCopies===2&&s.Let===0&&s.callSites===2);
  const nativeShared=await runNativeSuffixWitness(fixture,B.term_higher(shared));
  const nativeControl=await runNativeSuffixWitness(fixture,B.term_higher(control));
  const nativeRoundtrip=await runNativeSuffixWitness(fixture,B.term_higher(B.term_lower(B.term_higher(shared))));
  return {fixture:fixture.name,bindingQuantity:'Lone',quantityReason:'Mutually exclusive Mat branches join by max, not sequential addition; function types are Type, never Data.',
    representationSurvives,shared:sharedStages,duplicatedControl:controlStages,
    native:{shared:nativeShared,control:nativeControl,roundtrip:nativeRoundtrip},
    counting:'Existing Observation: full Lam/All/Let HOAS callbacks opened with bound Vars once per node; arrays/patterns/Quant included, spans and opaque closure captures excluded. Converters receive no observation cache. Residual body means body after its two explicit parameter Lambdas, including nested syntax; copies counted by distinct definition-body roots, not runtime execution.',
    closureCaveat:'HOAS closures may retain input syntax; captured memory is opaque. All reported higher syntax counts include materialized bodies, not opaque immediate closure counts.'};
}
