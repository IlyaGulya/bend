import * as B from '../bend2/bend.ts';
import {readParserGraph,type ParserGraph} from './parser_full_graph.ts';
import {renderBody} from './parser_full_body_render.ts';
import type {ExplicitProgressProgram,ExplicitEffectOperation,Progress} from './parser_full_explicit_progress.ts';
import type {ExplicitTransition} from './parser_full_explicit_certificate.ts';
import {createHash} from 'node:crypto';

type Origin={owner:string;offset:number;binderId:number};
type Value={kind:'data';tag:string;fields:Value[];origins?:Origin[]}|{kind:'function';name:string;args:Value[]}|{kind:'closure';node:B.LTerm;env:Map<number,Value>;owner:string}|undefined;
type Packet={value:Value;progress:Progress;origins:Origin[]};
type Frame={name:string;owner:string;pushOffset:number;inputFamily:number;fields:readonly {name:string}[]};
export type ExplicitLowering={graph:ParserGraph;sourceGraph:ParserGraph;lifted:ReadonlySet<string>;selected:ReadonlySet<string>;classifications:readonly {caller:string;callee:string;offset:number;kind:string;machineSource?:string}[];frames:readonly Frame[];steps:ReadonlyMap<string,string>;consumerHelpers:ReadonlyMap<string,string>;runtimeBlocks:ReadonlyMap<string,string>;rawChunks:ReadonlyMap<string,string>};
type FunctionContext={name:string;args:Value[];key:string;outputs:Packet[]};
type Definition={body:B.Body;parameters:number[];owner:string};
type Stack={kind:'empty';key:string}|{kind:'frame';frame:Value;tail:Stack;key:string}|{kind:'barrier';frame:Value;key:string};
type State={key:string;control:Value;stack:Stack;parent?:State;parentProgress?:Progress};
const hash=(text:string)=>createHash('sha256').update(text).digest('hex').slice(0,16);
const combine=(a:Progress,b:Progress):Progress=>a==='Consumed'||b==='Consumed'?'Consumed':'NoProgress';
const origins=(a:Origin[],b:Origin[])=>[...new Map([...a,...b].map(o=>[o.owner+':'+o.offset+':'+o.binderId,o])).values()];
const datum=(tag:string,...fields:Value[]):Value=>({kind:'data',tag,fields});
const plain=(value:Value):Packet=>({value,progress:'NoProgress',origins:[]});
const merge=(a:Packet,b:Packet):Packet=>({value:b.value,progress:combine(a.progress,b.progress),origins:origins(a.origins,b.origins)});
const isData=(value:Value,tag?:string):value is Extract<Value,{kind:'data'}>=>!!value&&value.kind==='data'&&(!tag||value.tag===tag);

/** Evaluate the actual emitted writer AST and actual runtime transition ABI.
 * Function summaries keep semantic values and Progress in the same packet.
 * Continuations are real stack cells, never edges from a shared child Outcome
 * to unrelated callers. No token identity, suffix, rank or relation is inferred. */
export async function explicitMachineTransitions(program:ExplicitProgressProgram,lowering:ExplicitLowering){
 const missingSupport=[...program.supportDeclarations].filter(([name])=>!lowering.graph.signatures.has(name)).map(([,source])=>source);
 const graph=missingSupport.length?await readParserGraph(lowering.graph.source+'\n'+program.typeDeclarations.join('\n\n')+'\n'+missingSupport.join('\n\n')):lowering.graph;
 const definitions=new Map<string,Definition>();
 for(const[name,signature]of graph.signatures){const body=graph.bodies.get(name);if(body)definitions.set(name,{body,parameters:signature.parameters.map(p=>p[2]),owner:name});}
 for(const[name,fn]of program.functions)definitions.set(fn.emittedName,{body:fn.body,parameters:fn.signature.parameters.map(p=>p[2]),owner:name});
 for(const[name,fn]of program.supportFunctions)definitions.set(name,{body:fn.body,parameters:fn.signature.parameters.map(p=>p[2]),owner:name});
 const contexts=new Map<string,FunctionContext>(),edges=new Map<string,ExplicitTransition>();
 const nativeCalls=new Map<string,Set<string>>();
 let evaluatingContext:FunctionContext|undefined;
 const nodeIds=new WeakMap<object,number>();let nodeCounter=0,waves=0;
 const nodeId=(node:object)=>{let id=nodeIds.get(node);if(id===undefined){id=++nodeCounter;nodeIds.set(node,id);}return id;};
 const metadataTags=new Set(['FeedbackControl','FeedbackKont','FeedbackResume','FeedbackCall','FeedbackDone','FeedbackInvariant','KontProgress','NoProgress','Consumed','WitnessNone','WitnessTail','WitnessFields',...lowering.frames.map(f=>f.name),...[...lowering.selected].map(n=>'Request_'+n)]);
 function valueKey(value:Value):string{
  if(!value)return '?';
  if(value.kind==='data')return value.tag+'('+value.fields.map(valueKey).join(',')+')'+(value.origins?.length?'@'+value.origins.map(o=>o.owner+':'+o.offset+':'+o.binderId).sort().join(','):'');
  if(value.kind==='function')return 'fn:'+value.name+'['+value.args.map(valueKey).join(',')+']';
  return 'lambda:'+nodeId(value.node)+'['+[...value.env].sort(([a],[b])=>a-b).map(([id,v])=>id+'='+valueKey(v)).join(';')+']';
 }
 function metadata(value:Value):boolean{return isData(value)&&(metadataTags.has(value.tag)||value.fields.some(metadata));}
 function normalize(value:Value,seen=new Set<string>(),keep=false):Value{
  if(!value||value.kind!=='data')return value;
  const preserve=keep||metadataTags.has(value.tag)||value.tag==='Tuple'&&isData(value.fields[1])&&['NoProgress','Consumed'].includes(value.fields[1].tag);
  if(!preserve&&seen.has(value.tag))return{...value,fields:value.fields.map(()=>undefined)};
  const next=new Set(seen);next.add(value.tag);
  return{...value,fields:value.fields.map(field=>normalize(field,preserve?new Set():next,keep||value.tag==='Con'&&metadata(value)))};
 }
 function context(name:string,args:Value[]):FunctionContext{
  const values=args.map(v=>normalize(v,new Set(),program.supportFunctions.has(name))),key=name+'['+values.map(valueKey).join(';')+']';
  let c=contexts.get(key);if(!c){c={name,args:values,key,outputs:[]};contexts.set(key,c);}
  if(evaluatingContext){let calls=nativeCalls.get(evaluatingContext.key);if(!calls){calls=new Set();nativeCalls.set(evaluatingContext.key,calls);}calls.add(c.key);}
  return c;
 }
 function distinct(packets:Packet[]):Packet[]{
  const result=new Map<string,Packet>();
  for(const packet of packets){const p={...packet,value:normalize(packet.value)},key=p.progress+':'+valueKey(p.value),prior=result.get(key);result.set(key,prior?{...p,origins:origins(prior.origins,p.origins)}:p);}
  return[...result.values()];
 }
 function progress(value:Value):Progress{
  if(isData(value,'NoProgress'))return 'NoProgress';if(isData(value,'Consumed'))return 'Consumed';
  throw Error('Generated Progress is not an explicit NoProgress/Consumed value: '+valueKey(value));
 }
 function progressOrigins(value:Value):Origin[]{return isData(value,'Consumed')?value.origins??[]:[];}
 function allProgressOrigins(values:Value[]):Origin[]{let result:Origin[]=[];for(const value of values)if(isData(value)){result=origins(result,progressOrigins(value));result=origins(result,allProgressOrigins(value.fields));}return result;}
 function sourceWitness(node:B.LTerm):ExplicitEffectOperation|undefined{
  return program.consumptionExpressions.get(node)??program.consumptionLiterals.get(node);
 }
 function bind(pattern:B.Patt,value:Value,env:Map<number,Value>):boolean{
  if(pattern.$==='PVar'){env.set(pattern.i,value);return true;}
  if(value&&!isData(value,pattern.k))return false;
  return pattern.x.every((field,i)=>bind(field,isData(value)?value.fields[i]:undefined,env));
 }
 function patternValue(pattern:B.Patt):Value{return pattern.$==='PCtr'?datum(pattern.k,...pattern.x.map(patternValue)):undefined;}
 function definite(pattern:B.Patt,value:Value):boolean{return pattern.$==='PVar'||isData(value,pattern.k)&&pattern.x.every((field,i)=>definite(field,value.fields[i]));}
 function argumentPackets(args:readonly B.LTerm[],env:Map<number,Value>,owner:string):{values:Value[];packet:Packet}[]{
  let rows=[{values:[] as Value[],packet:plain(undefined)}];
  for(const arg of args)rows=rows.flatMap(row=>evaluate(arg,env,owner).map(packet=>({values:[...row.values,packet.value],packet:merge(row.packet,packet)})));
  return rows;
 }
 function definitionOf(name:string):Definition|undefined{
  const cached=definitions.get(name);if(cached)return cached;
  const declaration=graph.parserBook.tlds[name];if(declaration?.$!=='Def'||!declaration.v)return undefined;
  let value=B.term_lower(declaration.v);const parameters:number[]=[];
  while(value.$==='Lam'){parameters.push(value.i);value=value.f;}
  const result={body:{$:'Reply',x:value} as B.Body,parameters,owner:name};definitions.set(name,result);return result;
 }
 const constructorArities=new Map<string,number>();
 function constructorArity(tag:string):number{
  const cached=constructorArities.get(tag);if(cached!==undefined)return cached;
  const constructor=graph.parserBook.ctrs[tag],datatype=Object.values(graph.parserBook.tlds).find(d=>d.$==='ADT'&&d.c.some(c=>c.k===tag));
  if(!constructor||datatype?.$!=='ADT')throw Error('Native match constructor lacks a declaration '+tag);
  let type=B.term_lower(constructor.T),count=0;while(type.$==='All'){count++;type=type.B;}
  const arity=count-datatype.n;constructorArities.set(tag,arity);return arity;
 }
 function applyMatcher(node:B.LTerm,input:Value,remaining:Value[],env:Map<number,Value>,owner:string):Packet[]{
  const output:Packet[]=[];let match=node;const excluded=new Set<string>();
  while(match.$==='Mat'){
   if(!input||isData(input,match.k)){
    const fields=isData(input)?input.fields:Array.from({length:constructorArity(match.k)},()=>undefined);
    output.push(...applyValue({kind:'closure',node:match.h,env,owner},[...fields,...remaining],owner));
    if(input)return output;
   }
   excluded.add(match.k);match=match.m;
  }
  if(match.$==='Lam'&&(!isData(input)||!excluded.has(input.tag)))output.push(...applyValue({kind:'closure',node:match,env,owner},[input,...remaining],owner));
  return output;
 }
 function applyValue(fn:Value,args:Value[],owner:string):Packet[]{
  if(!fn)return[plain(undefined)];
  if(fn.kind==='function'){
   const values=[...fn.args,...args],definition=definitionOf(fn.name);
   if(!definition)return[plain(undefined)];
   if(values.length<definition.parameters.length)return[plain({kind:'function',name:fn.name,args:values})];
   return context(fn.name,values.slice(0,definition.parameters.length)).outputs.flatMap(packet=>values.length===definition.parameters.length?[packet]:applyValue(packet.value,values.slice(definition.parameters.length),owner).map(p=>merge(packet,p)));
  }
  if(fn.kind!=='closure')throw Error('Native generated AST applies a non-function '+valueKey(fn));
  let node=fn.node,env=new Map(fn.env),remaining=[...args];
  while(node.$==='Lam'&&remaining.length){env.set(node.i,remaining.shift());node=node.f;}
  if(node.$==='Lam')return[plain({kind:'closure',node,env,owner:fn.owner})];
  if(node.$==='Mat'&&remaining.length)return applyMatcher(node,remaining.shift(),remaining,env,fn.owner);
  return evaluate(node,env,fn.owner).flatMap(packet=>remaining.length?applyValue(packet.value,remaining,owner).map(p=>merge(packet,p)):[packet]);
 }
 function evaluate(term:B.LTerm,env:Map<number,Value>,owner:string):Packet[]{
  const result=evaluateInner(term,env,owner),witness=sourceWitness(term);
  if(!witness)return result;
  return result.map(packet=>{
   const flag=progress(packet.value);
   if(flag==='NoProgress')return packet;
   const evidence={owner:witness.owner,offset:witness.sourceOffset,binderId:witness.binderId!};
   return{...packet,value:isData(packet.value,'Consumed')?{...packet.value,origins:origins(packet.value.origins??[],[evidence])}:packet.value,progress:'Consumed',origins:origins(packet.origins,[evidence])};
  });
 }
 function evaluateInner(term:B.LTerm,env:Map<number,Value>,owner:string):Packet[]{
  if(term.$==='Var')return[plain(env.get(term.i))];
  if(term.$==='Ann')return evaluate(term.x,env,owner);
  if(term.$==='Ref'){
   const definition=definitionOf(term.k);
   return definition&&!definition.parameters.length?context(term.k,[]).outputs:[plain({kind:'function',name:term.k,args:[]})];
  }
  if(term.$==='Lam'||term.$==='Mat')return[plain({kind:'closure',node:term,env:new Map(env),owner})];
  if(term.$==='Ctr')return argumentPackets(term.x,env,owner).map(row=>{
   const value:Value={kind:'data',tag:term.k,fields:row.values,...(term.k==='Consumed'?{origins:allProgressOrigins([...env.values()])}:{})};
   return{...row.packet,value};
  });
  if(term.$==='Sub'){const source=term.v.$==='PVar'||term.v.$==='PCtr'?B.patt_term(term.v):term.v;return evaluate(source,env,owner).flatMap(packet=>{const next=new Map(env);next.set(term.i,packet.value);return evaluate(term.f,next,owner).map(p=>merge(packet,p));});}
  if(term.$==='Let'){
   let rows=[{env,packet:plain(undefined)}];
   for(let i=0;i<term.v.length;i++)rows=rows.flatMap(row=>evaluate(term.v[i]!,row.env,owner).map(packet=>{const next=new Map(row.env);next.set(term.i[i]!,packet.value);return{env:next,packet:merge(row.packet,packet)};}));
   return rows.flatMap(row=>evaluate(term.f,row.env,owner).map(p=>merge(row.packet,p)));
  }
  if(term.$==='App'){
   const[head,args]=B.term_unapply(term);
   if(head.$==='Mat')return argumentPackets(args,env,owner).flatMap(row=>{
    if(!row.values.length)return[plain({kind:'closure',node:head,env,owner})];
    return applyMatcher(head,row.values[0],row.values.slice(1),env,owner).map(p=>merge(row.packet,p));
   });
   return evaluate(head,env,owner).flatMap(fn=>argumentPackets(args,env,owner).flatMap(row=>applyValue(fn.value,row.values,owner).map(p=>merge(merge(fn,row.packet),p))));
  }
  if(term.$==='Efq')return[];
  return[plain(undefined)];
 }
 function body(node:B.Body,env:Map<number,Value>,owner:string):Packet[]{
  if(node.$==='Reply')return evaluate(node.x,env,owner);
  if(node.$==='Local'){
   let rows=[{env,packet:plain(undefined)}];
   for(let i=0;i<node.v.length;i++)rows=rows.flatMap(row=>evaluate(node.v[i]!,row.env,owner).flatMap(packet=>{const next=new Map(row.env);return bind(node.k[i]!,packet.value,next)?[{env:next,packet:merge(row.packet,packet)}]:[];}));
   return rows.flatMap(row=>body(node.f,row.env,owner).map(p=>merge(row.packet,p)));
  }
  return argumentPackets(node.e,env,owner).flatMap(input=>node.r.flatMap((row,index)=>{
   if(node.r.slice(0,index).some(earlier=>earlier.p.every((p,i)=>definite(p,input.values[i]))))return[];
   const next=new Map(env);if(!row.p.every((p,i)=>bind(p,input.values[i],next)))return[];
   node.e.forEach((term,i)=>{if(term.$==='Var')next.set(term.i,input.values[i]??patternValue(row.p[i]!));});
   return body(row.f,next,owner).map(p=>merge(input.packet,p));
  }));
 }
 const checkedNativeRecursion=new Set<string>();
 function verifyNativeRecursion():void{
  const seen=new Set<string>(),active=new Map<string,number>(),recursive=new Set<string>();
  for(const root of contexts.keys()){
   if(seen.has(root))continue;
   const work=[{key:root,index:0,calls:[...(nativeCalls.get(root)??[])]}];seen.add(root);active.set(root,0);
   while(work.length){
    const top=work[work.length-1]!;
    if(top.index===top.calls.length){active.delete(top.key);work.pop();continue;}
    const next=top.calls[top.index++]!,ancestor=active.get(next);
    if(ancestor!==undefined){for(let index=ancestor;index<work.length;index++)recursive.add(contexts.get(work[index]!.key)!.name);continue;}
    if(seen.has(next))continue;
    seen.add(next);active.set(next,work.length);work.push({key:next,index:0,calls:[...(nativeCalls.get(next)??[])]});
   }
  }
  const pending=[...recursive].filter(name=>!checkedNativeRecursion.has(name));
  if(!pending.length)return;
  const usedNames=new Set([...contexts.values()].map(c=>c.name)),references=new Map<string,Set<string>>();
  function inspectNative(node:unknown,refs:Set<string>):void{
   if(!node||typeof node!=='object')return;
   const term=node as Record<string,unknown>;
   if(term.$==='Ref'&&typeof term.k==='string'&&usedNames.has(term.k))refs.add(term.k);
   for(const[key,child]of Object.entries(term))if(key!=='s')if(Array.isArray(child))for(const value of child)inspectNative(value,refs);else inspectNative(child,refs);
  }
  for(const name of usedNames){const refs=new Set<string>();inspectNative(definitionOf(name)!.body,refs);refs.delete(name);references.set(name,refs);}
  const completed=new Set<string>(),visiting=new Set<string>();
  for(const root of usedNames){
   if(completed.has(root))continue;
   const work=[{name:root,index:0,refs:[...(references.get(root)??[])]}];visiting.add(root);
   while(work.length){
    const top=work[work.length-1]!;
    if(top.index===top.refs.length){completed.add(top.name);visiting.delete(top.name);work.pop();continue;}
    const next=top.refs[top.index++]!;
    if(visiting.has(next))throw Error('Native recursive evaluation lacks a checked structural termination proof: mutually recursive definitions '+work.map(frame=>frame.name).join(' -> ')+' -> '+next);
    if(completed.has(next))continue;
    visiting.add(next);work.push({name:next,index:0,refs:[...(references.get(next)??[])]});
   }
  }
  const book={...graph.parserBook,tlds:{...graph.parserBook.tlds},order:[...graph.parserBook.order]};
  const signatures=new Map(graph.signatures);
  for(const fn of program.functions.values())signatures.set(fn.emittedName,fn.signature);
  for(const[name,fn]of program.supportFunctions)signatures.set(name,fn.signature);
  for(const name of signatures.keys())delete book.tlds[name];
  for(const[name,signature]of signatures){
   const definition=definitionOf(name);
   if(!definition)throw Error('Native recursive evaluation lacks a checked structural termination proof: missing '+name);
   const rendered=renderBody(definition.body,signature.parameters,{book:graph.parserBook});
   B.parse_book(book,'',`def ${name}(${rendered.parameters}) -> ${rendered.renderTerm(signature.result)}:
${rendered.body}
`);
  }
  for(const name of pending){
   const declaration=book.tlds[name],imported=graph.parserBook.tlds[name];
   if(declaration?.$!=='Def'||!declaration.v||imported?.$==='Def'&&imported.u)throw Error('Native recursive evaluation lacks a checked structural termination proof: '+name);
   const value=declaration.v;
   const qs=B.tele_unbind(book,declaration.T).doms.map(domain=>domain[0]).slice(0,declaration.n);
   book.tlds[name]={...declaration,v:null};
   try{B.term_check(book,{t:B.Ref(name),n:declaration.n,def:name,qs},value,B.Lone(),declaration.T,B.ctx_nil(),0);}
   catch(error){throw Error('Native recursive evaluation lacks a checked structural termination proof: '+name+'\\n'+(error&&typeof error==='object'&&'$'in error&&error.$==='Err'?B.err_show(error as B.Err):String(error)));}
   book.tlds[name]=declaration;
   checkedNativeRecursion.add(name);
  }
 }
 function settle():void{
  let changed=true;
  while(changed){changed=false;waves++;const count=contexts.size;
   for(const c of [...contexts.values()]){
    const definition=definitions.get(c.name);if(!definition)throw Error('Missing native generated definition '+c.name);
    const env=new Map(definition.parameters.map((id,i)=>[id,c.args[i]]));
    const previous=evaluatingContext;evaluatingContext=c;
    let evaluated:Packet[];
    try{evaluated=body(definition.body,env,definition.owner);}finally{evaluatingContext=previous;}
    const next=distinct([...c.outputs,...evaluated]);
    if(next.length!==c.outputs.length||next.some((p,i)=>p.origins.length!==c.outputs[i]?.origins.length)){c.outputs=next;changed=true;}
   }
   if(contexts.size!==count)changed=true;
  }
  for(const c of contexts.values())if(!c.outputs.length)throw Error('Reachable native evaluation has no productive summary; termination is unproved: '+c.key);
  verifyNativeRecursion();
 }
 const empty:Stack={kind:'empty',key:'[]'},barrierTails=new Map<string,Map<string,Stack>>(),stacks=new Map<string,Stack>([['[]',empty]]);
 let stackChanges=0;
 function push(frame:Value,tail:Stack):Stack{
  if(!isData(frame,'FeedbackKont'))throw Error('Pending continuation is not the actual FeedbackKont ABI');
  const saved=frame.fields[1],key=(progress(saved)==='Consumed'?'B:':'N:')+hash(valueKey(frame))+(progress(saved)==='Consumed'?'':':'+tail.key);
  if(progress(saved)==='Consumed'){
   let tails=barrierTails.get(key);if(!tails){tails=new Map();barrierTails.set(key,tails);}
   if(!tails.has(tail.key)){tails.set(tail.key,tail);stackChanges++;}
  }
  let stack=stacks.get(key);if(!stack){stack=progress(saved)==='Consumed'?{kind:'barrier',frame,key}:{kind:'frame',frame,tail,key};stacks.set(key,stack);}return stack;
 }
 function list(value:Value):Value[]{const result:Value[]=[];let rest=value;while(isData(rest,'Con')){result.push(rest.fields[0]);rest=rest.fields[1];}if(!isData(rest,'Nil'))throw Error('Generated pending list is not structural Con/Nil: '+valueKey(rest));return result;}
 function pending(control:Value,tail:Stack):Stack{
  if(!isData(control,'FeedbackControl'))throw Error('Native emitted function did not produce FeedbackControl: '+valueKey(control));
  const frames=list(control.fields[1]);let stack=tail;for(let i=frames.length-1;i>=0;i--)stack=push(frames[i],stack);return stack;
 }
 const states=new Map<string,State>();
 function state(control:Value,stack:Stack,parent?:State,label?:Progress):State{
  const value=normalize(control),key='Control:'+hash(valueKey(value))+'|'+stack.key;
  let result=states.get(key);if(!result){result={key,control:value,stack,parent,parentProgress:label};states.set(key,result);}return result;
 }
 function emit(from:string,to:string,packet:Packet,owner:string,operation:string,offset=0):void{
  if(packet.progress==='Consumed'&&!packet.origins.length)throw Error('Explicit Consumed has no mechanically emitted activation witness: '+operation);
  const edge:ExplicitTransition={from,to,progress:packet.progress,owner,offset,line:graph.source.slice(0,offset).split('\n').length,operation,driverTicks:1,consumptionOperations:packet.origins,propagation:'explicit-composition'};
  edges.set(from+'\0'+to+'\0'+edge.progress+'\0'+operation,edge);
 }
 function extendWithNoFrames(candidate:Stack,ancestor:Stack):boolean{
  let stack=candidate;let extended=false;while(stack.kind==='frame'){if(stack.key===ancestor.key)return extended;extended=true;stack=stack.tail;}return extended&&stack.key===ancestor.key;
 }
 function target(from:State,control:Value,stack:Stack,packet:Packet,owner:string,operation:string):void{
  if(packet.progress==='NoProgress')for(let ancestor:State|undefined=from;ancestor;ancestor=ancestor.parentProgress==='NoProgress'?ancestor.parent:undefined){
   if(valueKey(control)===valueKey(ancestor.control)&&extendWithNoFrames(stack,ancestor.stack)){
    emit(from.key,ancestor.key,packet,owner,operation+'; actual NoProgress stack-push pump');return;
   }
  }
  const next=state(control,stack,from,packet.progress);emit(from.key,next.key,packet,owner,operation);
 }
 // Generated step entrypoints are real initial Controls; ordinary/resume
 // helpers are evaluated only where their actual caller supplies arguments.
 const roots=[...program.functions].filter(([name,fn])=>fn.resultKind==='control'&&name.startsWith('step_'));
 for(const[,fn]of roots)context(fn.emittedName,fn.signature.parameters.map(()=>undefined));
 settle();
 for(const[,fn]of roots)for(const packet of context(fn.emittedName,fn.signature.parameters.map(()=>undefined)).outputs)state(packet.value,empty);
 let changed=true;
 while(changed){changed=false;const beforeStates=states.size,beforeEdges=edges.size,beforeContexts=contexts.size,beforeStacks=stackChanges;
  for(const current of [...states.values()]){
   if(!isData(current.control,'FeedbackControl'))throw Error('Unknown generated Control value');
   const action=current.control.fields[0];
   if(isData(action,'FeedbackCall')){
    const stack=pending(current.control,current.stack),request=action.fields[0];
    for(const packet of context('feedback_dispatch',[request]).outputs){
     if(!isData(packet.value,'FeedbackControl'))throw Error('Dispatch did not return the actual Control ABI');
     const own=packet.value.fields[3],proof={...packet,progress:progress(own),origins:progressOrigins(own)};
     target(current,packet.value,stack,proof,'feedback_dispatch','Dispatch actual generated Request; use explicit current own_progress');
    }
   }else if(isData(action,'FeedbackDone')){
    const stack=pending(current.control,current.stack);if(stack.kind==='empty')continue;
    const tails=stack.kind==='barrier'?[...barrierTails.get(stack.key)!.values()]:[stack.tail];
    for(const packet of context('feedback_resume',[stack.frame,action.fields[0],current.control.fields[2]]).outputs){
     if(!isData(packet.value,'FeedbackResume'))throw Error('Resume did not produce explicit FeedbackResume envelope');
     const own=packet.value.fields[2],proof={...packet,progress:progress(own),origins:progressOrigins(own)};
     if(stack.kind==='barrier'&&proof.progress==='NoProgress'&&(tails.length!==1||tails[0]!.key===stack.key))
      throw Error('Balanced administrative proof cannot merge propagated-only Consumed continuation tails');
     for(const tail of tails)target(current,packet.value.fields[0],tail,proof,'feedback_resume','Pop exact matching continuation; preserve cumulative Progress and use explicit fresh own_progress');
    }
   }else if(!isData(action,'FeedbackInvariant'))throw Error('Unknown generated action '+valueKey(action));
  }
  settle();
  if(states.size!==beforeStates||edges.size!==beforeEdges||contexts.size!==beforeContexts||stackChanges!==beforeStacks)changed=true;
 }
 return{nodes:[...states.keys()],edges:[...edges.values()],analysisIterations:waves,invocations:contexts.size,
  semantics:'Actual transformed writer AST and generated runtime ABI; correlated packets, exact continuation prefixes, explicit own_progress driver effects',
  configurations:[...states.values()].map(s=>({node:s.key,control:valueKey(s.control),stack:s.stack.key})),
  proofBoundary:'Fresh own_progress excludes propagated cumulative credits; structural input-cell charging must be established before production N-bound certification'};
}
