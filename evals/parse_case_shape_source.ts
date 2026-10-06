import * as B from '../bend2/bend.ts';
import {readParserGraph} from './parser_full_graph.ts';
import {LexicalTypes,freeBinderIds,type Binding} from './parser_full_type_env.ts';
import {createHash} from 'node:crypto';
const sha=(s:string)=>createHash('sha256').update(s).digest('hex');
const show=(t:B.LTerm)=>B.term_show(t).replace(/\bast\./g,'Ast.').replace(/\blexer\./g,'Lexer.');
export async function extractCaseShape(source:string){return extractTwoRowShape(source,'parse_case_row_body','case_row','colon');}
export async function extractMatchTailShape(source:string){return extractTwoRowShape(source,'parse_match_tail_after_semicolon','match_tail','end');}
export async function extractMatchTailScanShape(source:string){return extractTwoRowShape(source,'parse_match_tail_scan','match_tail_scan','close');}
export async function extractBraceRightShape(source:string){return extractTwoRowShape(source,'parse_brace_equal_right_result','brace_equal_right','colon');}
export async function extractBraceAnnotShape(source:string){return extractOwnedTailShape(source,'parse_brace_annot_type_result','brace_annot');}
export async function extractInequalityShape(source:string){return extractOwnedTailShape(source,'parse_inequality_type_result','inequality');}
export async function extractInequalityRightShape(source:string){return extractTwoRowShape(source,'parse_inequality_right_result','inequality_right','colon');}
export async function extractAllNamedTypeShape(source:string){return extractTwoRowShape(source,'parse_all_named_type_result','all_named_type','arrow');}
export async function extractIndexResultShape(source:string){return extractTwoRowShape(source,'parse_index_result','index_result','close');}
export async function extractRewriteMotiveShape(source:string){return extractTwoRowShape(source,'parse_rewrite_motive','rewrite_motive','colon');}
export async function extractMatchScrutineesShape(source:string){return extractTwoRowShape(source,'parse_match_scrutinees','match_scrutinees','colon');}
export async function extractDefinitionHeaderShape(source:string){return extractTwoRowShape(source,'parse_definition_after_binders_scan','definition_header','header');}
export async function extractDefinitionBodyShape(source:string){return extractTwoRowShape(source,'parse_definition_body_scan','definition_body','token');}
async function extractOwnedTailShape(source:string,name:'parse_brace_annot_type_result'|'parse_inequality_type_result',helper:string){
 const graph=await readParserGraph(source),body=graph.bodies.get(name),sig=graph.signatures.get(name);
 if(body?.$!=='Match'||body.r[0]!.f.$!=='Match'||!sig)throw Error('Owned-tail success branch drift');
 const success=body.r[0]!.f.r[0]!.f,expression=success.$==='Reply'?success.x:success.$==='Local'?success.v[0]!:success.e[0]!,types=new LexicalTypes(graph.parserBook,graph.signatures);types.indexBody(body,sig.parameters,sig.result);
 const tail=[...types.environmentAt(expression).values()].find(b=>b.name==='tail');if(!tail||tail.quantity.$!=='Lone')throw Error('Owned-tail quantity drift');
 const spans:Array<{beg:number,end:number}>=[];
 function visit(value:unknown){if(!value||typeof value!=='object')return;if(Array.isArray(value)){value.forEach(visit);return;}const node=value as Record<string,unknown>;if(node.$==='Var'&&node.i===tail!.id){const s=node.s as {beg:number,end:number}|undefined;if(!s||source.slice(s.beg,s.end)!=='tail')throw Error('Annotation tail reference span drift');spans.push(s);}for(const [key,child]of Object.entries(node))if(key!=='s'&&key!=='b')visit(child);}
 visit(success);if(spans.length!==1)throw Error('Owned-tail reference count drift');
 const span=spans[0]!,projection='List.tail(&2, Lexer.Token, after_ty)',projected=source.slice(0,span.beg)+projection+source.slice(span.end);
 if(projected.slice(0,span.beg)+'tail'+projected.slice(span.beg+projection.length)!==source)throw Error('Annotation projection inverse differs');
 const result=await extractTwoRowShape(projected,name,helper,'close');
 return{...result,audit:{...result.audit,originalSha256:sha(source),ownedTailProjection:{binderId:tail.id,quantity:tail.quantity.$,originalSpan:span,expression:projection,outerNonemptyGuard:true,exactInverse:true,noListCopy:true}}};
}
async function extractTwoRowShape(source:string,name:'parse_case_row_body'|'parse_match_tail_after_semicolon'|'parse_match_tail_scan'|'parse_brace_equal_right_result'|'parse_brace_annot_type_result'|'parse_inequality_type_result'|'parse_inequality_right_result'|'parse_all_named_type_result'|'parse_index_result'|'parse_rewrite_motive'|'parse_match_scrutinees'|'parse_definition_after_binders_scan'|'parse_definition_body_scan',helper:string,token:string){
 const graph=await readParserGraph(source),body=graph.bodies.get(name),sig=graph.signatures.get(name);
 if(body?.$!=='Match'||body.r.length!==2||body.r[0]!.f.$!=='Match'||!sig)throw Error('Case scanner shape drift');
 const match=body.r[0]!.f;if(match.r.length!==(name==='parse_match_tail_scan'||name==='parse_definition_after_binders_scan'?3:2))throw Error('Token selector row drift');
 const types=new LexicalTypes(graph.parserBook,graph.signatures);types.indexBody(body,sig.parameters,sig.result);
 const line=(n:number)=>source.lastIndexOf('\n',n)+1,begin=line(match.e[0]!.s!.beg),end=line(body.r[1]!.p[0]!.s!.beg),original=source.slice(begin,end),helpers:string[]=[],calls:string[]=[],audit:object[]=[];
 const all=new Map<number,Binding>();
 for(const [i,row]of match.r.entries()){
  const first=row.f.$==='Reply'?row.f.x:row.f.$==='Local'?row.f.v[0]!:row.f.e[0]!,env=types.environmentAt(first),ids=new Set<number>();
  function expression(t:B.LTerm){for(const id of freeBinderIds(t))if(env.has(id))ids.add(id);}
  function visit(b:B.Body){if(b.$==='Reply')expression(b.x);else if(b.$==='Local'){b.v.forEach(expression);visit(b.f);}else{b.e.forEach(expression);b.r.forEach(r=>visit(r.f));}}visit(row.f);
  const captures=[...ids].sort((a,b)=>a-b).map(id=>env.get(id)!);captures.forEach(b=>all.set(b.id,b));
  const beg=source.indexOf('\n',source.indexOf(':',Math.max(...row.p.map(p=>p.s!.end))))+1,finish=i+1<match.r.length?line(match.r[i+1]!.p[0]!.s!.beg):end,text=source.slice(beg,finish),indent=text.match(/^ */)![0].length;
  helpers.push('def '+helper+'_branch_'+i+'('+captures.map(b=>(b.quantity.$==='Many'?'+':'')+b.name+': '+show(b.type)).join(', ')+') -> '+show(sig.result)+':\n'+text.trimEnd().split('\n').map(s=>'  '+s.slice(indent)).join('\n')+'\n');
  calls.push(helper+'_branch_'+i+'('+captures.map(b=>b.name).join(', ')+')');audit.push({row:i,originalBodySha256:sha(text),captures:captures.map(b=>({name:b.name,quantity:b.quantity.$,type:show(b.type)}))});
 }
 const captures=[...all.values()].sort((a,b)=>a.id-b.id),params=captures.map(b=>(b.quantity.$==='Many'?'+':'')+b.name+': '+show(b.type)).join(', '),args=captures.map(b=>b.name).join(', ');
 const enumPrefix=name==='parse_definition_after_binders_scan'?'DefinitionHeader':'MatchTailScan',action=match.r.length===2?'Bool':enumPrefix+'Action',labels=match.r.map((_,i)=>match.r.length===2?(i===0?'True{}':'False{}'):enumPrefix+'Row'+i+'{}'),data=match.r.length===2?'':'type '+action+' is Data:\n'+labels.map(l=>'  '+l).join('\n')+'\n\n';
 const predicate='def '+helper+'_is_colon('+token+': Lexer.Token) -> '+action+':\n  match '+token+':\n'+match.r.map((r,i)=>'    case '+r.p.map(p=>source.slice(p.s!.beg,p.s!.end)).join(' ')+':\n      '+labels[i]+'\n').join('')+'\n';
 const run='def '+helper+'_run(is_colon: '+action+', '+params+') -> '+show(sig.result)+':\n  match is_colon:\n'+calls.map((call,i)=>'    case '+labels[i]+':\n      '+call+'\n').join('')+'\n';
 const replacement='      '+helper+'_run('+helper+'_is_colon('+token+'), '+args+')\n',prefix=data+helpers.join('\n')+'\n'+predicate+run,insert=source.indexOf('def '+name+'(');
 let changed=source.slice(0,begin)+replacement+source.slice(end);changed=changed.slice(0,insert)+prefix+changed.slice(insert);
 if(changed.replace(prefix,'').replace(replacement,original)!==source)throw Error('Case scanner inverse differs');
 const fresh=await readParserGraph(changed);return{source:changed,graph:fresh,audit:{originalSha256:sha(source),transformedSha256:sha(changed),exactInverse:true,externalABIUnchanged:true,grammarCopiedOnly:true,branches:audit}};
}
