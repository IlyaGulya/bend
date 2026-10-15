/** A bounded counterexample search, not a full-machine termination certificate.
 * Runs the unchanged generic lowering with Bend's existing JS core reducer.
 * Token-list index observers exist only on the model's closed input terms.
 */
import {readFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {fileURLToPath} from 'node:url';
import * as B from '../bend2/bend.ts';
import {inspectExplicitProgressGraph, type ExplicitTransition} from './parser_full_explicit_certificate.ts';

const path=fileURLToPath(new URL('../bend2/selfhost/parser_full_generated.bend.frontier-source.bend',import.meta.url));
const metadata=JSON.parse(readFileSync(path.replace('.frontier-source.bend','.frontier-input.json'),'utf8'));
const book=B.book_nil();
await B.book_load(book,path,'',new Map());
const source=readFileSync(fileURLToPath(new URL('../bend2/selfhost/parser.bend',import.meta.url)));
if(createHash('sha256').update(source).digest('hex')!==metadata.sourceSha256)throw Error('Canonical source differs from model input');
const depthArg=process.argv.find(x=>x.startsWith('--depth='));
const depth=depthArg?Number(depthArg.slice(8)):2;
if(!Number.isSafeInteger(depth)||depth<2)throw Error('Witness needs an integer nesting depth >= 2');
const specs:Array<[string,string]>=[];
for(let i=0;i<depth;i++)specs.push(['NameToken','Foo'],['SymbolToken','{']);
specs.push(['NameToken','a']);
for(let i=0;i<depth;i++)specs.push(['SymbolToken','}']);
const tokens='['+specs.map(([kind,text],i)=>`Lexer.TokenInfo{Lexer.${kind}{}, ${JSON.stringify(text)}, ${i}n, ${i+1}n, 0n, ${i}n}`).join(',')+']';
function closed(str:string):B.HTerm {
 const p:B.Parse={book,dir:fileURLToPath(new URL('../bend2/selfhost/',import.meta.url)),str,pos:0,stk:[],frs:0,ns:'',al:{Lexer:'lexer',Ast:'ast'}};
 return B.term_higher(B.parse_term(p as B.Parse));
}
function normal(term:B.HTerm){return B.term_wnf(book,term);}
function ctor(term:B.HTerm){const t=normal(term);if(t.$!=='Ctr')throw Error('Expected constructor, got '+t.$);return t;}
function apply(name:string,args:B.HTerm[]){let t=B.Ref(name) as B.HTerm;for(const arg of args)t=B.App(t,arg);return t;}
function nat(term:B.HTerm){const n=B.nat_from_term(B.term_lower(normal(term)));if(n===null)throw Error('Expected Nat ordinal');return n;}
let active=false,frontier=0,reads:number[]=[];
const input=closed(tokens);
// The immutable input lineage is "witness"; these are input-list positions,
// not pointer identity, token ownership effects, or changes to Lexer.Token.
for(let node=ctor(input),index=0;;index++){
 const tag=node.k,position=index;
 Object.defineProperty(node,'k',{get(){if(active){reads.push(position);frontier=Math.max(frontier,position);}return tag;},enumerable:true,configurable:true});
 if(tag==='Nil')break;
 if(tag!=='Con')throw Error('Expected token list');
 node=ctor(node.x[1]!);
}
function run(term:B.HTerm){
 const before=frontier;reads=[];active=true;let value:B.HTerm;
 try{value=normal(term);}finally{active=false;}
 return {value,before,after:frontier,reads:[...reads]};
}
function request(control:B.HTerm){const c=ctor(control),a=ctor(c.x[0]!);if(a.k!=='FeedbackCall')throw Error('Witness stopped at '+a.k);return ctor(a.x[0]!);}
function cursor(req:B.HTerm){const r=ctor(req),list=ctor(r.x[1]!);return list.k==='Nil'?specs.length:nat(ctor(list.x[0]!).x[2]!);}
function frames(control:B.HTerm){
 const out:string[]=[];let list=ctor(ctor(control).x[1]!);
 while(list.k==='Con'){const frame=ctor(list.x[0]!);if(frame.k!=='FeedbackKont')throw Error('Unexpected pending frame');out.push(ctor(frame.x[0]!).k);list=ctor(list.x[1]!);}
 if(list.k!=='Nil')throw Error('Unexpected pending stack');return out;
}
const init=run(apply('step_parse_body',[closed('""'),input,closed('[]'),closed('0n'),closed('0n')]));
const bodyRequest=request(init.value);
const prefix=run(apply('feedback_dispatch',[bodyRequest]));
const atomRequest=request(prefix.value);
if(bodyRequest.k!=='Request_parse_body_scan'||atomRequest.k!=='Request_parse_atom_scan')throw Error('Generated prefix changed');
if(prefix.after!==specs.length||cursor(atomRequest)!==0)throw Error('Pattern lookahead did not reach input end and restore root');
const replay=run(apply('feedback_dispatch',[atomRequest]));
const next=request(replay.value),beforeCursor=cursor(atomRequest),afterCursor=cursor(next);
if(next.k!==atomRequest.k||beforeCursor!==0||afterCursor!==2||replay.after!==replay.before)throw Error('Expected covered-region atomic self-loop');
// The original input observer may be lost on reconstructed list constructors.
// For this edge, actual cursor 0 -> 2 proves scanning; the whole immutable
// lineage is already covered, so no reconstruction can make it FreshProgress.
const transitions=[
 {from:bodyRequest.k,to:atomRequest.k,classification:'FreshProgress',frontierBefore:prefix.before,frontierAfter:prefix.after,reads:prefix.reads},
 {from:atomRequest.k,to:next.k,classification:'Replay',frontierBefore:replay.before,frontierAfter:replay.after,cursorBefore:beforeCursor,cursorAfter:afterCursor,reads:replay.reads},
];
const noFresh=transitions.filter(t=>t.classification!=='FreshProgress');
const inspection=inspectExplicitProgressGraph([bodyRequest.k,atomRequest.k],noFresh.map((t):ExplicitTransition=>({from:t.from,to:t.to,progress:'NoProgress',owner:'parse_atom_scan',offset:0,line:0,operation:'covered-region generated dispatch',driverTicks:1,consumptionOperations:[],propagation:'literal-NoProgress'})));
if(!inspection.smallestRemainingCycle||inspection.smallestRemainingCycle.edges.length!==1)throw Error('Expected minimum one-edge cycle');
console.log(JSON.stringify({
 schemaVersion:1,authority:'bounded-actual-generated-frontier-counterexample',decision:'B',
 sourceSha256:metadata.sourceSha256,loweredBodies:metadata.completedLiftedBodies,input:{lineage:'witness',nestingDepth:depth,tokens:specs.length},
 model:{execution:'unchanged Bend JS core reducer and unchanged raw generic lowering',projection:'Request control label; cursor/frontier and pending frames retained as edge evidence',fresh:'strict advancement beyond prior high-water',replay:'actual scanning within already covered immutable input',administrative:'no observed token activity',stoppingRule:'stop at first shortest possible non-fresh control cycle',globalMachineTotalsComputed:false},
 initialization:{frontierBefore:init.before,frontierAfter:init.after,driverTransition:false,note:'Core reduction initializes the deferred Request; only dispatch transitions are classified below.'},transitions,
 counts:{observedDriverTransitions:transitions.length,FreshProgress:1,Replay:1,Administrative:0,NoFreshProgress:noFresh.length,controlNodes:inspection.nodes.length,cyclicSCCs:inspection.cyclicSCCs.length,globalTransitions:null,globalSCCs:null},
 noFreshCyclicSCCs:inspection.cyclicSCCs,smallestCycle:{nodes:inspection.smallestRemainingCycle.nodes,driverTicks:1,classification:'Replay',cursor:{lineage:'witness',before:beforeCursor,after:afterCursor,frontier:replay.before},rewind:{sourceLines:[3421,3423],reason:'native constructor-pattern lookahead falls back to parse_reply on original tokens'},pendingFramesBefore:frames(prefix.value),newPendingFrames:frames(replay.value),existingFramesRetained:true,stateChanges:['cursor advances 0 -> 2 inside covered input','three new Kont frames','frontier unchanged','Request control label unchanged'],exactSemanticStateCycle:false},
 bound:{H:null,expression:null,reason:'Arbitrarily deep constructor-pattern lookahead admits arbitrarily many repeated covered-region atom dispatches; no frontier-only constant H is certified.'},
},null,2));
