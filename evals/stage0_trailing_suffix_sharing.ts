import * as B from '../bend2/bend.ts';
import {readParserGraph,type ParserParameter} from './parser_full_graph.ts';
import {suffixFixtures,type Fixture} from './stage0_trailing_suffix_fixtures.ts';
import {trailingSuffixEligibility} from './stage0_trailing_suffix_eligibility.ts';

type Syntax=B.LTerm|B.HTerm;
export type WitnessNativeResult={validated:boolean;cases:number};
export type WitnessNativeRunner=(fixture:Fixture,witness:B.HTerm)=>Promise<WitnessNativeResult>;
export type IdentityCounts={graphObjects:number;termNodes:number;quantMetadata:number;closureFunctions:number};
export type WitnessStage={
  stage:'constructed-lower'|'higher'|'roundtrip-lower'|'final-higher';
  suffixRootIdentity:boolean;
  whole:IdentityCounts;
  suffix:{prefixFailure:IdentityCounts;outerDefault:IdentityCounts;union:IdentityCounts;intersection:IdentityCounts};
  opaqueImmediate:IdentityCounts|null;
  observedCallbacks:number;
};
export type SuffixSharingResult={
  fixture:string;
  representationSharingSurvives:boolean;
  decision:'STOP'|'representation-survives';
  constructedTermNodeSavings:number;
  finalTermNodeSavings:number;
  retainedTermNodeSavingsFraction:number;
  shared:WitnessStage[];
  unshared:WitnessStage[];
  native:WitnessNativeResult|null;
  lazyClosureCaveat:string;
  counting:string;
};

function requireShape(condition:boolean,message:string):asserts condition {
  if(!condition)throw Error('Trailing suffix witness shape: '+message);
}

export function checkFixture(body:B.Body,parameters:ParserParameter[]):asserts body is B.Match {
  requireShape(parameters.length===3,'exactly tag, flag, later parameters');
  const names=['tag','flag','later'],types=['Tag','Bool','Bool'];
  parameters.forEach((p,j)=>requireShape(p[1]===names[j]&&p[3].$==='Ref'&&p[3].k===types[j],'parameter '+j));
  requireShape(body.$==='Match','top-level Match');
  requireShape(body.e.length===3&&body.e.every((e,j)=>e.$==='Var'&&e.i===parameters[j][2]),'scrutinees in declaration order');
  requireShape(body.r.length===4,'four rows');
  const patterns=[['C','True','True'],['C','True','False'],['_','False','True'],['_','_','_']];
  const values=[1,2,30,40];
  body.r.forEach((row,j)=>{
    requireShape(row.p.length===3,'three patterns per row');
    row.p.forEach((p,k)=>requireShape(patterns[j][k]==='_'?p.$==='PVar'&&p.k==='_':p.$==='PCtr'&&p.k===patterns[j][k]&&p.x.length===0,'zero-field pattern '+j+':'+k));
    requireShape(row.f.$==='Reply'&&B.nat_from_term(row.f.x)===values[j],'literal-only Reply '+j+' (no original Tag or wildcard capture)');
  });
  const eligibility=trailingSuffixEligibility(body.r,'C');
  requireShape(eligibility.eligible&&eligibility.boundary===2&&eligibility.wildcardSuffixRows===2,'closed trailing wildcard suffix');
}

/** Only this asserted fixture is assembled; this is not a match compiler. */
export function compileResidual(body:B.Match,parameters:ParserParameter[]):B.LTerm {
  const vars=parameters.slice(1).map(([q,k,i,,s]):B.PVar=>({$:'PVar',q,k,i,s}));
  const match:B.Match={$:'Match',e:body.e.slice(1),r:body.r.slice(2).map(row=>({p:row.p.slice(1),f:row.f})),s:body.s};
  let fresh=Math.max(...parameters.map(p=>p[2]),...body.r.flatMap(row=>row.p.flatMap(p=>p.$==='PVar'?[p.i]:[])))+1;
  return B.body_flatten(match,vars,()=>fresh++);
}

function assembleWitness(body:B.Match,parameters:ParserParameter[],failure:B.LTerm,outer:B.LTerm):B.LTerm {
  const [tag,,later]=parameters;
  const first=body.r[0].f,second=body.r[1].f;
  requireShape(first.$==='Reply'&&second.$==='Reply','prefix literal Replies');
  const laterDefault:B.LTerm=B.Lam(later[1],later[2],second.x,later[4],later[0]);
  const laterMatch:B.LTerm=B.Mat('True',first.x,laterDefault,body.r[0].p[2].s);
  const flagMatch:B.LTerm=B.Mat('True',laterMatch,failure,body.r[0].p[1].s);
  const tagDefault:B.LTerm=B.Lam(tag[1],tag[2],outer,tag[4],tag[0]);
  return B.Mat('C',flagMatch,tagDefault,body.r[0].p[0].s);
}

function objectValue(value:unknown):value is object {
  return value!==null&&(typeof value==='object'||typeof value==='function');
}

/** Observation-only materialization. Its callback edges never enter conversions. */
export class Observation {
  readonly termNodes=new Set<object>();
  readonly quantMetadata=new Set<object>();
  readonly edges=new Map<object,object[]>();
  readonly bodies=new Map<object,Syntax>();
  readonly observedCallbacks=new Set<object>();
  private readonly visited=new Set<object>();
  constructor(private readonly materialize:boolean){}

  private scan(node:object):void {
    if(this.edges.has(node))return;
    const children:object[]=[];
    this.edges.set(node,children);
    if('$' in node&&(node.$==='None'||node.$==='Lone'||node.$==='Many'))this.quantMetadata.add(node);
    for(const [key,value]of Object.entries(node))if(key!=='s'&&objectValue(value)){
      children.push(value);
      this.scan(value);
    }
  }

  visit(term:Syntax,depth=0):void {
    this.scan(term);
    if(this.visited.has(term))return;
    this.visited.add(term);
    this.termNodes.add(term);
    const visit=(child:Syntax,d=depth)=>this.visit(child,d);
    const body=(callback:()=>Syntax,nextDepth:number)=>{
      if(!this.materialize)return;
      const result=callback();
      this.observedCallbacks.add(term);
      this.bodies.set(term,result);
      this.edges.get(term)!.push(result);
      visit(result,nextDepth);
    };
    switch(term.$){
      case 'Var':if(term.v!==undefined)visit(term.v);return;
      case 'Sub':if(term.v.$!=='PVar'&&term.v.$!=='PCtr')visit(term.v);visit(term.f);return;
      case 'Lam':{
        const f=term.f;
        if(typeof f==='function')body(()=>f(B.Var(term.k,depth)),depth+1);
        else {this.bodies.set(term,f);visit(f,depth+1);}
        return;
      }
      case 'All':{
        visit(term.A);
        const f=term.B;
        if(typeof f==='function')body(()=>f(B.Var(term.k,depth)),depth+1);
        else {this.bodies.set(term,f);visit(f,depth+1);}
        return;
      }
      case 'Let':{
        term.v.forEach(v=>visit(v));
        const f=term.f;
        if(typeof f==='function')body(()=>f(term.k.map((k,j):B.HTerm=>B.Var(k,depth+j))),depth+term.k.length);
        else {this.bodies.set(term,f);visit(f,depth+term.k.length);}
        return;
      }
      case 'Typ':visit(term.g);return;
      case 'Min':visit(term.a);visit(term.b);return;
      case 'App':visit(term.f);visit(term.x);return;
      case 'ADT':case 'Ctr':term.x.forEach(x=>visit(x));return;
      case 'Mat':visit(term.h);visit(term.m);return;
      case 'Eql':visit(term.a);visit(term.b);visit(term.T);return;
      case 'Rwt':visit(term.e);visit(term.p);visit(term.f);return;
      case 'Ann':visit(term.x);visit(term.T);return;
      case 'Ref':case 'Qnt':case 'Qua':case 'Efq':case 'Rfl':case 'Hol':return;
    }
  }

  descendants(root:object):Set<object> {
    const seen=new Set<object>(),pending=[root];
    while(pending.length){const node=pending.pop()!;if(seen.has(node))continue;seen.add(node);pending.push(...(this.edges.get(node)??[]));}
    return seen;
  }
  counts(nodes:Set<object>):IdentityCounts {
    let graphObjects=0,termNodes=0,quantMetadata=0,closureFunctions=0;
    for(const node of nodes){
      if(typeof node==='function')closureFunctions++;else graphObjects++;
      if(this.termNodes.has(node))termNodes++;
      if(this.quantMetadata.has(node))quantMetadata++;
    }
    return {graphObjects,termNodes,quantMetadata,closureFunctions};
  }
}

function measure(root:Syntax,stage:WitnessStage['stage']):WitnessStage {
  requireShape(root.$==='Mat'&&root.k==='C'&&root.h.$==='Mat'&&root.h.k==='True'&&root.m.$==='Lam','witness C split with prefix failure and outer Lam');
  const higher=stage==='higher'||stage==='final-higher';
  const observation=new Observation(true);
  observation.visit(root);
  const failure=root.h.m,outer=observation.bodies.get(root.m);
  requireShape(outer!==undefined,'outer default callback observed');
  const left=observation.descendants(failure),right=observation.descendants(outer);
  const union=new Set([...left,...right]),intersection=new Set([...left].filter(node=>right.has(node)));
  let opaqueImmediate:IdentityCounts|null=null;
  if(higher){const opaque=new Observation(false);opaque.visit(root);opaqueImmediate=opaque.counts(opaque.descendants(root));}
  return {stage,suffixRootIdentity:failure===outer,whole:observation.counts(observation.descendants(root)),
    suffix:{prefixFailure:observation.counts(left),outerDefault:observation.counts(right),union:observation.counts(union),intersection:observation.counts(intersection)},
    opaqueImmediate,observedCallbacks:observation.observedCallbacks.size};
}

function stages(witness:B.LTerm):WitnessStage[] {
  const constructed=measure(witness,'constructed-lower');
  const higher=B.term_higher(witness);
  const high=measure(higher,'higher');
  // Conversion calls are intentionally independent of observation callback results.
  const lower=B.term_lower(higher);
  const low=measure(lower,'roundtrip-lower');
  const final=B.term_higher(lower);
  return [constructed,high,low,measure(final,'final-higher')];
}

export async function runSuffixSharingWitness(nativeRunner?:WitnessNativeRunner):Promise<SuffixSharingResult> {
  const fixture=suffixFixtures.find(item=>item.name==='eligible-closed');
  requireShape(fixture!==undefined,'eligible-closed fixture exists');
  const graph=await readParserGraph(fixture.source);
  const body=graph.bodies.get('matrix'),signature=graph.signatures.get('matrix');
  requireShape(body!==undefined&&signature!==undefined,'actual matrix Body and signature');
  checkFixture(body,signature.parameters);
  const residual=compileResidual(body,signature.parameters);
  const sharedWitness=assembleWitness(body,signature.parameters,residual,residual);
  // Reparse the same raw source, rather than clone source/Quant graphs or reuse
  // literal leaf objects from the first residual's source Body.
  const independent=await readParserGraph(fixture.source);
  const secondBody=independent.bodies.get('matrix'),secondSignature=independent.signatures.get('matrix');
  requireShape(secondBody!==undefined&&secondSignature!==undefined,'independent raw-source control');
  checkFixture(secondBody,secondSignature.parameters);
  requireShape(secondSignature.parameters.every((p,j)=>p[2]===signature.parameters[j][2]&&p[0].$===signature.parameters[j][0].$),'same parameter indexes and quantities');
  const secondResidual=compileResidual(secondBody,signature.parameters);
  requireShape(secondResidual!==residual,'control residual independently compiled');
  const unsharedWitness=assembleWitness(body,signature.parameters,residual,secondResidual);
  const shared=stages(sharedWitness),unshared=stages(unsharedWitness);
  requireShape(shared[0].suffixRootIdentity&&!unshared[0].suffixRootIdentity,'constructed identity contrast');
  const constructedTermNodeSavings=unshared[0].whole.termNodes-shared[0].whole.termNodes;
  const finalTermNodeSavings=unshared[3].whole.termNodes-shared[3].whole.termNodes;
  const retainedTermNodeSavingsFraction=constructedTermNodeSavings>0?finalTermNodeSavings/constructedTermNodeSavings:0;
  const representationSharingSurvives=shared.slice(1).every(stage=>stage.suffixRootIdentity&&stage.suffix.intersection.termNodes>0)&&retainedTermNodeSavingsFraction>0.5;
  const native=nativeRunner?await nativeRunner(fixture,B.term_higher(sharedWitness)):null;
  return {fixture:fixture.name,representationSharingSurvives,decision:representationSharingSurvives?'representation-survives':'STOP',
    constructedTermNodeSavings,finalTermNodeSavings,retainedTermNodeSavingsFraction,shared,unshared,native,
    lazyClosureCaveat:'Opaque HOAS callbacks close over the original lower graph, which may retain shared input syntax. Immediate counts cannot prove output sharing. Materialized counts invoke every Lam/All/Let body once with bound Vars at traversal depth; callback observations are not reused by term_lower or term_higher. Closure capture memory is opaque and not counted.',
    counting:'Identity unions/intersections of enumerable graph edges plus observed callback bodies; Span/source edges (s) excluded. Arrays/pattern metadata/Quant objects count as graph objects. Functions reported separately. Term nodes exclude pattern and Quant metadata. No conversion caching or converter changes.'};
}
