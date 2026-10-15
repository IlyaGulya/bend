import * as B from '../bend2/bend.ts';
import {readParserGraph} from './parser_full_graph.ts';
import {LexicalTypes,freeBinderIds} from './parser_full_type_env.ts';
import {createHash} from 'node:crypto';
const sha=(s:string)=>createHash('sha256').update(s).digest('hex');
function callParts(source:string,offset:number){
 const open=source.indexOf('(',offset);let depth=0,quote='',escape=false,start=open+1;const args:string[]=[];
 for(let i=open+1;i<source.length;i++){const ch=source[i]!;
  if(quote){if(escape)escape=false;else if(ch==='\\')escape=true;else if(ch===quote)quote='';continue;}
  if(ch==='"'||ch==="'"){quote=ch;continue;}
  if('({['.includes(ch)){depth++;continue;}
  if(ch===')'&&depth===0){args.push(source.slice(start,i).trim());return{end:i+1,args};}
  if(')}]'.includes(ch)){depth--;continue;}
  if(ch===','&&depth===0){args.push(source.slice(start,i).trim());start=i+1;}
 }
 throw Error('Unterminated scanner call');
}
export async function localPatternScanSource(source:string){
 const graph=await readParserGraph(source),body=graph.bodies.get('pattern_scan'),sig=graph.signatures.get('pattern_scan');
 if(body?.$!=='Match'||body.r.length!==20||!sig||sig.parameters[0]?.[1]!=='tokens')throw Error('Frozen scanner drift');
 const lexical=new LexicalTypes(graph.parserBook,graph.signatures);lexical.indexBody(body,sig.parameters,sig.result);
 const calls=graph.calls.get('pattern_scan')!.filter(c=>c.callee==='pattern_scan');
 const edits:{beg:number;end:number;before:string;after:string}[]=[],helpers:string[]=[],audit:object[]=[];
 const show=(t:B.LTerm)=>B.term_show(t).replace(/\bast\./g,'Ast.').replace(/\blexer\./g,'Lexer.').replace(/\bcore\./g,'Core.');
 for(let rowIndex=10;rowIndex<20;rowIndex++){
  const row=body.r[rowIndex]!;if(row.f.$!=='Match'||row.f.e[0]?.$!=='Var'||row.f.e[0].k!=='frames')throw Error('Expected frames decision row');
  const rowBeg=Math.max(...row.p.map(p=>p.s!.end));const colon=source.indexOf(':',rowBeg),beg=source.indexOf('\n',colon)+1;
  const end=rowIndex+1<20?source.lastIndexOf('\n',body.r[rowIndex+1]!.p[0]!.s!.beg)+1:source.indexOf('\ndef ',beg);
  if(end<beg)throw Error('Body boundary missing');
  const rowCalls=calls.filter(c=>c.offset>=beg&&c.offset<end),scope=lexical.environmentAt(row.f.e[0]),ids=new Set<number>();
  function term(t:B.LTerm){const[head,args]=B.term_unapply(t);if(head.$==='Ref'&&head.k==='pattern_scan'&&args.length===7){for(const a of args.slice(2))for(const id of freeBinderIds(a))if(scope.has(id))ids.add(id);return;}for(const id of freeBinderIds(t))if(scope.has(id))ids.add(id);}
  function visit(b:B.Body){if(b.$==='Local'){b.v.forEach(term);visit(b.f);}else if(b.$==='Match'){b.e.forEach(term);b.r.forEach(r=>visit(r.f));}else term(b);}
  visit(row.f);
  const bindings=[...ids].map(id=>scope.get(id)!).sort((a,b)=>(a.name==='frames'?-1:b.name==='frames'?1:a.id-b.id));
  const helper='pattern_scan_frame_'+rowIndex;
  const parameters=bindings.map(b=>(b.quantity.$==='Many'?'+':'')+b.name+': '+show(b.type));
  const continuationType='PatternScanMode -> List<&2, PatternFrame> -> List<&2, Scope> -> Nat -> PatternScanGoal -> PatternScanOutcome';
  if(rowCalls.length)parameters.push('continue_scan: '+continuationType);
  let helperBody=source.slice(beg,end);let cursor:string|undefined;
  for(const call of [...rowCalls].sort((a,b)=>b.offset-a.offset)){
   const parts=callParts(source,call.offset);if(parts.args.length!==7||parts.args[1]!=='file')throw Error('Recursive ABI drift');
   if(cursor!==undefined&&cursor!==parts.args[0])throw Error('Row consumes different token suffixes');cursor=parts.args[0];
   helperBody=helperBody.slice(0,call.offset-beg)+'continue_scan('+parts.args.slice(2).join(', ')+')'+helperBody.slice(parts.end-beg);
  }
  helperBody=helperBody.split('\n').map(line=>line.startsWith('    ')?line.slice(4):line).join('\n');
  helpers.push('def '+helper+'('+parameters.join(', ')+') -> PatternScanOutcome:\n'+helperBody.trimEnd()+'\n');
  const actuals=bindings.map(b=>b.name);
  if(cursor)actuals.push('next_mode => next_frames => next_scope => next_depth => next_goal => pattern_scan('+cursor+', file, next_mode, next_frames, next_scope, next_depth, next_goal)');
  const replacement='      '+helper+'('+actuals.join(', ')+')\n';
  edits.push({beg,end,before:source.slice(beg,end),after:replacement});
  audit.push({rowIndex,helper,bodyOriginalSha256:sha(source.slice(beg,end)),helperBodySha256:sha(helperBody),capturedBindings:bindings.map(b=>({id:b.id,name:b.name,quantity:b.quantity.$,type:show(b.type)})),recursiveCalls:rowCalls.map(c=>({offset:c.offset,args:callParts(source,c.offset).args})),tokenSuffix:cursor??null,originalTokenFormalOrderPreserved:true});
 }
 const header=source.indexOf('def pattern_scan(');let transformed=source;for(const e of [...edits].sort((a,b)=>b.beg-a.beg))transformed=transformed.slice(0,e.beg)+e.after+transformed.slice(e.end);
 transformed=transformed.slice(0,header)+helpers.join('\n')+'\n'+transformed.slice(header);
 const fresh=await readParserGraph(transformed),next=fresh.bodies.get('pattern_scan');if(next?.$!=='Match'||next.r.length!==20)throw Error('Scanner rows changed');
 function pattern(p:B.Patt):object{return p.$==='PVar'?{$:p.$,k:p.k,q:p.q.$}:{$:p.$,k:p.k,x:p.x.map(pattern)};}
 for(let i=0;i<20;i++)if(JSON.stringify(body.r[i]!.p.map(pattern))!==JSON.stringify(next.r[i]!.p.map(pattern)))throw Error('Pattern/priority/quantity drift');
 if(fresh.signatures.get('pattern_scan')!.parameters.map(p=>p[1]).join()!==sig.parameters.map(p=>p[1]).join())throw Error('Scanner formal order changed');
 return{source:transformed,graph:fresh,audit:{question:'Do typed frame/goal helpers with token-tail continuation preserve native decreasing checks and allow real full parser build under3GiB?',cheapTest:'Ordinary native scanner continuation smoke returned7n with shrinking original first token argument; no checker modification',onPass:'Full ordinary load/check/codegen then released JS comparison, not target-only acceptance',onFailure:'Fix only local scanner implementation; no checker weakening/unsafe/generic match changes',originalSha256:sha(source),transformedSha256:sha(transformed),rows:20,rowOrderPatternsQuantitiesUnchanged:true,originalScannerFormalsAndExternalActualsUnchanged:true,helpers:audit,sourceSpecificGeneratorExceptions:0}};
}
