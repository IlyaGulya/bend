import { expect, test } from "bun:test";
import { buildProgressCertificate, inspectProgressGraph, type ProgressEdge } from "./parser_full_progress_certificate.ts";
import { readParserGraph } from "./parser_full_graph.ts";
import { analyzeTokenProvenance } from "./parser_full_token_provenance.ts";

function edge(from: string, to: string, relation: ProgressEdge["relation"]): ProgressEdge {
  return { from, to, relation, classification: relation === "StrictSuffix" ? "consuming" : relation === "Unknown" ? "unknown" : "admin",
    driverTicks: 0, semantics: "Control direct evaluation", caller: from, callee: to, offset: 0, line: 1,
    sourceCursor: from + ":binder#0", destinationCursor: to + ":binder#0", sourceProvenance: {}, destinationProvenance: {},
    sourceConstruct: "fixture call", reason: "fixture relation" };
}

test("unknown edges remain in the uncertified graph and expose the smallest cycle", () => {
  const result = inspectProgressGraph(["a", "b", "c", "z"], [edge("a", "b", "Same"), edge("b", "c", "Suffix"),
    edge("c", "a", "Same"), edge("z", "z", "Unknown")]);
  expect(result.uncertified.cycle?.nodes).toEqual(["z", "z"]);
  expect(result.uncertified.cycle?.evidenceType).toBe("A");
  expect(result.knownNonconsuming.cycle?.nodes).toEqual(["a", "b", "c", "a"]);
  expect(result.knownNonconsuming.cycle?.evidenceType).toBe("A");
});

test("strict descent cuts cycles but a merely possible suffix does not", () => {
  const strict = inspectProgressGraph(["a", "b"], [edge("a", "b", "Same"), edge("b", "a", "StrictSuffix")]);
  expect(strict.uncertified.height).toBe(1);
  expect(strict.uncertified.cycle).toBeNull();
  expect(strict.uncertified.ranks).toEqual({ a: 1, b: 0 });
  const suffix = inspectProgressGraph(["a", "b"], [edge("a", "b", "Same"), edge("b", "a", "Suffix")]);
  expect(suffix.uncertified.cycle?.evidenceType).toBe("A");
  expect(suffix.uncertified.cycle?.edges.map(item => item.relation)).toEqual(["Same", "Suffix"]);
});

test("parallel callsites preserve the actual unknown edge in cycle evidence", () => {
  const uncertain = { ...edge("a", "b", "Unknown"), offset: 73, reason: "callback cursor is not proven" };
  const result = inspectProgressGraph(["a", "b"], [edge("a", "b", "StrictSuffix"), uncertain, edge("b", "a", "Same")]);
  expect(result.uncertified.cycle?.edges[0]?.offset).toBe(73);
  expect(result.uncertified.cycle?.edges[0]?.reason).toBe("callback cursor is not proven");
  expect(result.knownNonconsuming.cycle).toBeNull();
});

async function stackFixture(body:string,ownerBody='finish(worker(tokens))'){
 const graph=await readParserGraph(`import Base
type Token is Data:
  Item{}
def worker(tokens: List<&2, Token>) -> List<&2, Token>:
${body}
def finish(tokens: List<&2, Token>) -> List<&2, Token>:
  tokens
def owner(tokens: List<&2, Token>) -> List<&2, Token>:
  ${ownerBody}
`);
 const call=graph.calls.get('owner')!.find(c=>c.callee==='worker')!;
 const binderId=graph.signatures.get('owner')!.parameters[0]![2];
 return buildProgressCertificate(graph,analyzeTokenProvenance(graph,{tokenElement:'Token'}),{
  lifted:new Set(['owner','worker','finish']),selected:new Set(['worker']),
  classifications:[{caller:'owner',callee:'worker',offset:call.offset,kind:'non-tail'}],
  frames:[{name:'Frame',owner:'owner',pushOffset:call.offset,fields:[{name:'saved',binderId}]}],
 });
}
test('Same push and Same child completion preserve the suspended cursor',async()=>{
 const proof=await stackFixture('  tokens');
 const pop=proof.machine.edges.find(e=>e.to==='Kont:Frame')!;
 expect(pop.relation).toBe('Same');
 expect(pop.pushAncestry?.pushRelation).toBe('Same');
 expect(pop.pushAncestry?.completionRelation).toBe('Same');
});
const strictOwner='match tokens:\n    case head <> rest:\n      finish(worker(rest))\n    case Nil{}:\n      tokens';
test('StrictSuffix push and Same child completion retain strict descent',async()=>{
 const proof=await stackFixture('  tokens',strictOwner);
 expect(proof.machine.edges.find(e=>e.to==='Kont:Frame')!.relation).toBe('StrictSuffix');
});
async function productFixture(strictPush:boolean,opaque=false){
 const graph=await readParserGraph(`import Base
type Token is Data:
  Item{}
def worker(tokens: List<&2, Token>) -> List<&2, Token> & Bool:
  match tokens:
    case head <> rest:
      (${opaque?'external(rest)':'rest'}, True{})
    case Nil{}:
      (tokens, False{})
def finish(result: List<&2, Token> & Bool) -> List<&2, Token>:
  match result:
    case (cursor, flag):
      cursor
def owner(tokens: List<&2, Token>) -> List<&2, Token>:
${strictPush?'  match tokens:\n    case head <> rest:\n      finish(worker(rest))\n    case Nil{}:\n      tokens':'  finish(worker(tokens))'}
`);
 const call=graph.calls.get('owner')!.find(c=>c.callee==='worker')!;
 return buildProgressCertificate(graph,analyzeTokenProvenance(graph,{tokenElement:'Token'}),{
  lifted:new Set(['owner','worker','finish']),selected:new Set(['worker']),
  classifications:[{caller:'owner',callee:'worker',offset:call.offset,kind:'non-tail'}],
  frames:[{name:'Frame',owner:'owner',pushOffset:call.offset,fields:[{name:'saved',binderId:graph.signatures.get('owner')!.parameters[0]![2]}]}],
 });
}
test('Same push and StrictSuffix completion compose on the success branch',async()=>{
 const proof=await productFixture(false);
 const success=proof.machine.edges.find(e=>e.to==='Kont:Frame'&&e.pushAncestry?.guards.some(g=>g.constructor==='True'))!;
 expect(success.relation).toBe('StrictSuffix');
});
test('StrictSuffix push and StrictSuffix completion compose on the success branch',async()=>{
 const proof=await productFixture(true);
 const success=proof.machine.edges.find(e=>e.to==='Kont:Frame'&&e.pushAncestry?.guards.some(g=>g.constructor==='True'))!;
 expect(success.relation).toBe('StrictSuffix');
});
test('failure returning the child input remains strict relative to its parent',async()=>{
 const proof=await productFixture(true);
 const failure=proof.machine.edges.find(e=>e.to==='Kont:Frame'&&e.pushAncestry?.guards.some(g=>g.constructor==='False'))!;
 expect(failure.pushAncestry?.completionRelation).toBe('Same');
 expect(failure.relation).toBe('StrictSuffix');
});
test('product result projection preserves its cursor field provenance',async()=>{
 const proof=await productFixture(false);
 const success=proof.machine.edges.find(e=>e.to==='Kont:Frame'&&e.pushAncestry?.guards.some(g=>g.constructor==='True'))!;
 expect(success.pushAncestry?.resultPath).toEqual([0]);
 expect(success.pushAncestry?.completionRelation).toBe('StrictSuffix');
});
test('an opaque child result stays Unknown even after a strict push',async()=>{
 const proof=await productFixture(true,true);
 const success=proof.machine.edges.find(e=>e.to==='Kont:Frame'&&e.pushAncestry?.completionRelation==='Unknown')!;
 expect(success.pushAncestry?.completionRelation).toBe('Unknown');
 expect(success.relation).toBe('Unknown');
});
test('two frames of the same constructor preserve their strict push ancestry',async()=>{
 const graph=await readParserGraph(`import Base
type Token is Data:
  Item{}
def finish(tokens: List<&2, Token>) -> List<&2, Token>:
  tokens
def owner(tokens: List<&2, Token>) -> List<&2, Token>:
  match tokens:
    case head <> rest:
      finish(owner(rest))
    case Nil{}:
      tokens
`);
 const call=graph.calls.get('owner')!.find(c=>c.callee==='owner')!;
 const proof=buildProgressCertificate(graph,analyzeTokenProvenance(graph,{tokenElement:'Token'}),{
  lifted:new Set(['owner','finish']),selected:new Set(['owner']),
  classifications:[{caller:'owner',callee:'owner',offset:call.offset,kind:'non-tail'}],
  frames:[{name:'Frame',owner:'owner',pushOffset:call.offset,fields:[{name:'saved',binderId:graph.signatures.get('owner')!.parameters[0]![2]}]}],
 });
 const pop=proof.machine.edges.find(e=>e.from==='Kont:Frame'&&e.to==='Kont:Frame')!;
 expect(pop.relation).toBe('StrictSuffix');
 expect(pop.pushAncestry?.innerFrame).toBe('Frame');
 expect(pop.pushAncestry?.pushRelation).toBe('StrictSuffix');
});
test('unrelated suspended frames never supply pop proof evidence',async()=>{
 const graph=await readParserGraph(`import Base
type Token is Data:
  Item{}
def worker(tokens: List<&2, Token>) -> List<&2, Token>:
  tokens
def other(tokens: List<&2, Token>) -> List<&2, Token>:
  tokens
def finish(tokens: List<&2, Token>) -> List<&2, Token>:
  tokens
def owner(tokens: List<&2, Token>) -> List<&2, Token>:
  finish(worker(tokens))
def separate(tokens: List<&2, Token>) -> List<&2, Token>:
  finish(other(tokens))
`);
 const a=graph.calls.get('owner')!.find(c=>c.callee==='worker')!;
 const b=graph.calls.get('separate')!.find(c=>c.callee==='other')!;
 const proof=buildProgressCertificate(graph,analyzeTokenProvenance(graph,{tokenElement:'Token'}),{
  lifted:new Set(graph.definitions),selected:new Set(['worker','other']),
  classifications:[{caller:'owner',callee:'worker',offset:a.offset,kind:'non-tail'},{caller:'separate',callee:'other',offset:b.offset,kind:'non-tail'}],
  frames:[{name:'Left',owner:'owner',pushOffset:a.offset,fields:[{name:'saved',binderId:graph.signatures.get('owner')!.parameters[0]![2]}]},
   {name:'Right',owner:'separate',pushOffset:b.offset,fields:[{name:'saved',binderId:graph.signatures.get('separate')!.parameters[0]![2]}]}],
 });
 expect(proof.machine.edges.filter(e=>e.pushAncestry).map(e=>[e.from,e.to])).toEqual([['Control:worker','Kont:Left'],['Control:other','Kont:Right']]);
 expect(proof.stackAncestry).toEqual([]);
});
