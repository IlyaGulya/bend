import * as B from '../bend2/bend.ts';
import {readParserGraph} from './parser_full_graph.ts';
import {LexicalTypes,freeBinderIds} from './parser_full_type_env.ts';
import {createHash} from 'node:crypto';
const sha=(s:string)=>createHash('sha256').update(s).digest('hex');
const show=(t:B.LTerm)=>B.term_show(t).replace(/\bast\./g,'Ast.').replace(/\blexer\./g,'Lexer.');
export async function extractCaseShape(source:string){
 const graph=await readParserGraph(source),body=graph.bodies.get('parse_case_row_body'),sig=graph.signatures.get('parse_case_row_body');
 if(body?.$!=='Match'||body.r.length!==2||body.r[0]!.f.$!=='Match'||!sig)throw Error('Case scanner shape drift');
 const match=body.r[0]!.f;if(match.r.length!==2)throw Error('Case scanner row drift');
 const types=new LexicalTypes(graph.parserBook,graph.signatures);types.indexBody(body,sig.parameters,sig.result);
 const line=(n:number)=>source.lastIndexOf('\n',n)+1,begin=line(match.e[0]!.s!.beg),end=line(body.r[1]!.p[0]!.s!.beg),original=source.slice(begin,end),helpers:string[]=[],calls:string[]=[],audit:object[]=[];
 const all=new Map<number,ReturnType<typeof types.environmentAt> extends Map<number,infer T>?T:never>();
 for(const [i,row]of match.r.entries()){
  if(row.f.$!=='Reply')throw Error('Case scanner body drift');const env=types.environmentAt(row.f.x),ids=[...freeBinderIds(row.f.x)].filter(id=>env.has(id)).sort((a,b)=>a-b),captures=ids.map(id=>env.get(id)!);captures.forEach(b=>all.set(b.id,b));
  const beg=source.indexOf('\n',source.indexOf(':',Math.max(...row.p.map(p=>p.s!.end))))+1,finish=i===0?line(match.r[1]!.p[0]!.s!.beg):end,text=source.slice(beg,finish),indent=text.match(/^ */)![0].length;
  helpers.push('def case_row_branch_'+i+'('+captures.map(b=>(b.quantity.$==='Many'?'+':'')+b.name+': '+show(b.type)).join(', ')+') -> '+show(sig.result)+':\n'+text.trimEnd().split('\n').map(s=>'  '+s.slice(indent)).join('\n')+'\n');
  calls.push('case_row_branch_'+i+'('+captures.map(b=>b.name).join(', ')+')');audit.push({row:i,originalBodySha256:sha(text),captures:captures.map(b=>({name:b.name,quantity:b.quantity.$,type:show(b.type)}))});
 }
 const captures=[...all.values()].sort((a,b)=>a.id-b.id),params=captures.map(b=>(b.quantity.$==='Many'?'+':'')+b.name+': '+show(b.type)).join(', '),args=captures.map(b=>b.name).join(', ');
 const predicate='def case_row_is_colon(colon: Lexer.Token) -> Bool:\n  match colon:\n'+match.r.map((r,i)=>'    case '+r.p.map(p=>source.slice(p.s!.beg,p.s!.end)).join(' ')+':\n      '+(i===0?'True{}':'False{}')+'\n').join('')+'\n';
 const run='def case_row_run(is_colon: Bool, '+params+') -> '+show(sig.result)+':\n  match is_colon:\n    case True{}:\n      '+calls[0]+'\n    case False{}:\n      '+calls[1]+'\n\n';
 const replacement='      case_row_run(case_row_is_colon(colon), '+args+')\n',prefix=helpers.join('\n')+'\n'+predicate+run,insert=source.indexOf('def parse_case_row_body(');
 let changed=source.slice(0,begin)+replacement+source.slice(end);changed=changed.slice(0,insert)+prefix+changed.slice(insert);
 if(changed.replace(prefix,'').replace(replacement,original)!==source)throw Error('Case scanner inverse differs');
 const fresh=await readParserGraph(changed);return{source:changed,graph:fresh,audit:{originalSha256:sha(source),transformedSha256:sha(changed),exactInverse:true,externalABIUnchanged:true,grammarCopiedOnly:true,branches:audit}};
}
