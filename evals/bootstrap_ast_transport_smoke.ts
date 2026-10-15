import {encodeNativeAst,decodeNativeAst,writeNativeAst,readNativeAst,readNativeAstArena,nativeAstValue,semanticHash} from './bootstrap_ast_transport.ts';
import {createHash} from 'node:crypto';
import {writeFileSync,mkdtempSync,rmSync,existsSync} from 'node:fs';
import {guardHeavyGate} from './heavy_gate.ts';
import {strictEqual,deepStrictEqual,throws,rejects} from 'node:assert';
import {join} from 'node:path';
import {tmpdir} from 'node:os';
await guardHeavyGate(import.meta.path,{label:'Complete AST transport and semantic hash smoke'});
// --report=PATH permits repeat runs without overwriting historical evidence.
const reportPath=process.argv.find(argument=>argument.startsWith('--report='))?.slice(9)??'checkpoints/bootstrap-ast-transport-v237-smoke.json';
if(!reportPath||existsSync(reportPath))throw Error('Use a fresh --report=PATH; smoke evidence is never overwritten');
const hash=(value:unknown)=>createHash('sha256').update(JSON.stringify(value)).digest('hex');
const samples=[null,true,[-0,NaN,Infinity,undefined],{text:'λ\n"',list:[1,{tag:'App',fields:['x','y']}]},{omit:undefined,value:7}];
for(const value of samples)if(semanticHash(value)!==hash(value))throw Error('Exact JSON semantic hash mismatch');
const native={$:'Module',path:'λ.bend',imports:{$:'Nil'},declarations:{$:'Con',head:{$:'DefTop',definition:{$:'Definition',key:'f',binders:{$:'Nil'},result:{$:'SomeTerm',term:{$:'TermRef',key:'Nat',span:{$:'SpanOf',file:'λ.bend',beg:0,end:3}}},body:{$:'DefTerm',term:{$:'BodyReply',term:{$:'TermVar',key:'x',index:0,span:{$:'SpanOf',file:'λ.bend',beg:9,end:10}},span:{$:'SpanOf',file:'λ.bend',beg:9,end:10}}},unsafe:false,span:{$:'SpanOf',file:'λ.bend',beg:0,end:10}}},tail:{$:'Nil'}}};
const before=nativeAstValue(native),after=nativeAstValue(decodeNativeAst(encodeNativeAst(native)));
if(hash(before)!==hash(after))throw Error('Constructor field or scalar lost in transport');

// Graph identity and scalar/array semantics must survive in-place envelope consumption.
const shared={large:9007199254740993n,negativeZero:-0,nan:NaN,positiveInfinity:Infinity,negativeInfinity:-Infinity,missing:undefined,text:'λ\n"',flag:false};
const graph:any={first:shared,second:shared};graph.self=graph;
Object.defineProperty(graph,'__proto__',{value:'own transport field',enumerable:true});
const sparse:any[]=new Array(4);sparse[1]=undefined;sparse[3]=graph;graph.sparse=sparse;
const recovered:any=decodeNativeAst(encodeNativeAst(graph));
strictEqual(recovered.first,recovered.second);
strictEqual(recovered.self,recovered);
strictEqual(recovered.sparse[3],recovered);
strictEqual(recovered.sparse.length,4);
strictEqual(0 in recovered.sparse,false);
strictEqual(1 in recovered.sparse,true);
strictEqual(2 in recovered.sparse,false);
strictEqual(recovered.sparse[1],undefined);
strictEqual(recovered.__proto__,'own transport field');
strictEqual(Object.getPrototypeOf(recovered),Object.prototype);
deepStrictEqual(Object.keys(recovered),['first','second','self','__proto__','sparse']);
strictEqual(recovered.first.large,9007199254740993n);
strictEqual(Object.is(recovered.first.negativeZero,-0),true);
strictEqual(Number.isNaN(recovered.first.nan),true);
strictEqual(recovered.first.positiveInfinity,Infinity);
strictEqual(recovered.first.negativeInfinity,-Infinity);
strictEqual(Object.hasOwn(recovered.first,'missing'),true);
strictEqual(recovered.first.missing,undefined);
strictEqual(recovered.first.text,'λ\n"');strictEqual(recovered.first.flag,false);

const cyclicCtor:any={$:'AST.Cell',child:null,nat:7n,text:'payload',flag:true};cyclicCtor.child=cyclicCtor;
const cyclicValue:any=nativeAstValue(decodeNativeAst(encodeNativeAst(cyclicCtor)));
strictEqual(cyclicValue.tag,'Cell');strictEqual(cyclicValue.fields.length,4);
strictEqual(cyclicValue.fields[0],cyclicValue);
deepStrictEqual(cyclicValue.fields.slice(1),[7n,'payload',true]);
const scalars={$:'AST.Scalars',large:9007199254740993n,nat:2**53,negativeZero:-0};
const scalarValue:any=nativeAstValue(decodeNativeAst(encodeNativeAst(scalars)));
strictEqual(scalarValue.fields[0],9007199254740993n);
strictEqual(scalarValue.fields[1],2**53);
strictEqual(Object.is(scalarValue.fields[2],-0),true);
const cyclicList:any={$:'Con',head:1n,tail:null};cyclicList.tail=cyclicList;
throws(()=>nativeAstValue(decodeNativeAst(encodeNativeAst(cyclicList))),/Cyclic native AST list/);

const envelope=(root:unknown,records:unknown[])=>JSON.stringify({format:'bend-native-ast-v1',root,records});
// Unreachable records still require complete validation, not just root traversal.
for(const invalidSlot of [['ref',1],['bigint','NaN'],['undefined',0],['number','1'],['value',{}]])
 throws(()=>decodeNativeAst(envelope(['value',0],[['object',0,[['unreachable',invalidSlot]]]])),/Invalid native AST transport slot/);
throws(()=>decodeNativeAst(envelope(['ref',0],[])),/Invalid native AST transport slot/);
throws(()=>decodeNativeAst(envelope(['value',0],[['object',0,[[7,['value',1]]]]])),/Invalid native AST transport field/);
throws(()=>decodeNativeAst(envelope(['value',0],[['array',-1,[]]])),/Invalid native AST transport record/);

const streamDirectory=mkdtempSync(join(tmpdir(),'bend-ast-stream-'));
try{
 const streamPath=join(streamDirectory,'graph.json');
 const boundaryGraph={graph,text:('λ😀a\\"]},[\n').repeat(20000)};
 writeNativeAst(streamPath,boundaryGraph);
 const streamed=await readNativeAst(streamPath);
 deepStrictEqual(streamed.value,boundaryGraph);
 const scalarPath=join(streamDirectory,'scalars.json');
 writeNativeAst(scalarPath,scalars);
 const {arena}=await readNativeAstArena(scalarPath);
 deepStrictEqual(arena.semantic(arena.root),scalarValue);
 const invalidCases=[
  ...[['ref',1],['bigint','NaN'],['undefined',0],['number','1'],['value',{}]].map(slot=>envelope(['value',0],[['object',0,[['unreachable',slot]]]])),
  envelope(['ref',0],[]),
  envelope(['value',0],[['object',0,[[7,['value',1]]]]]),
  envelope(['value',0],[['array',-1,[]]]),
  envelope(['value',0],[]).slice(0,-1),
  '{"format":"bend-native-ast-v1","root":["value",0],"records":[["object",0,[]],]}',
 ];
 for(let i=0;i<invalidCases.length;i++){const path=join(streamDirectory,'invalid-'+i+'.json');writeFileSync(path,invalidCases[i]);await rejects(()=>readNativeAst(path));}
}finally{rmSync(streamDirectory,{recursive:true,force:true});}
let deep:any={$:'End'};const depth=40000;for(let i=depth-1;i>=0;i--)deep={$:'Cell',value:i,tail:deep};
let transported:any=decodeNativeAst(encodeNativeAst(deep));for(let i=0;i<depth;i++){if(transported.$!=='Cell'||transported.value!==i)throw Error('Deep field mismatch');transported=transported.tail;}if(transported.$!=='End')throw Error('Deep terminal lost');
const semantic=nativeAstValue(deep),expected=createHash('sha256');for(let i=0;i<depth;i++)expected.update('{"tag":"Cell","fields":['+i+',');expected.update('{"tag":"End","fields":[]}');for(let i=0;i<depth;i++)expected.update(']}');if(semanticHash(semantic)!==expected.digest('hex'))throw Error('Deep complete semantic hash mismatch');
const report={status:'PASS',shallowExactJSONHashCases:samples.length,nativeConstructorFieldsPreserved:true,transportSharingCyclesAndSparseArraysPreserved:true,completeEnvelopeValidation:true,nativeNumberNatsAndArbitraryBigIntsPreserved:true,arenaScalarIdentityPreserved:true,cyclicListsRejected:true,deepConstructorDepth:depth,deepCompleteHashMatched:true};writeFileSync(reportPath,JSON.stringify(report,null,2)+'\n',{flag:'wx'});console.log(JSON.stringify(report));
