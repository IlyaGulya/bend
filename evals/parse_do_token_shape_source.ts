import * as B from '../bend2/bend.ts';
import {readParserGraph} from './parser_full_graph.ts';
import {LexicalTypes,freeBinderIds} from './parser_full_type_env.ts';
import {createHash} from 'node:crypto';
const sha=(s:string)=>createHash('sha256').update(s).digest('hex');
const show=(t:B.LTerm)=>B.term_show(t).replace(/\bast\./g,'Ast.').replace(/\blexer\./g,'Lexer.');
export async function extractDoTokenShape(source:string){return extractTokenShape(source,'parse_do_typed_bind_type_token','do_token','DoTokenAction');}
export async function extractArrayShape(source:string){return extractTokenShape(source,'expr_match_array_shape','array_shape','ArrayShapeAction');}
export async function extractBraceEqualsShape(source:string){return extractTokenShape(source,'parse_brace_equals','brace_equals','BraceEqualsAction');}
async function extractTokenShape(source:string,name:'parse_do_typed_bind_type_token'|'expr_match_array_shape'|'parse_brace_equals',helper:string,action:string){
 const graph=await readParserGraph(source),body=graph.bodies.get(name),sig=graph.signatures.get(name);
 if(body?.$!=='Match'||body.r.length!==(name==='parse_brace_equals'?4:3)||!sig)throw Error('Direct token selector shape drift');
 const types=new LexicalTypes(graph.parserBook,graph.signatures);types.indexBody(body,sig.parameters,sig.result);
 const line=(n:number)=>source.lastIndexOf('\n',n)+1,begin=line(body.e[0]!.s!.beg),next=source.indexOf('\ndef ',begin),end=next+1,original=source.slice(begin,end),helpers:string[]=[],calls:string[]=[],audit:object[]=[];
 for(const [i,row]of body.r.entries()){
  if(row.f.$!=='Reply')throw Error('Typed do branch drift');const env=types.environmentAt(row.f.x),captures=[...freeBinderIds(row.f.x)].filter(id=>env.has(id)).sort((a,b)=>a-b).map(id=>env.get(id)!);
  const beg=source.indexOf('\n',source.indexOf(':',Math.max(...row.p.map(p=>p.s!.end))))+1,finish=i+1<body.r.length?line(body.r[i+1]!.p[0]!.s!.beg):end,text=source.slice(beg,finish),indent=text.match(/^ */)![0].length;
  helpers.push('def '+helper+'_branch_'+i+'('+captures.map(b=>(b.quantity.$==='Many'?'+':'')+b.name+': '+show(b.type)).join(', ')+') -> '+show(sig.result)+':\n'+text.trimEnd().split('\n').map(s=>'  '+s.slice(indent)).join('\n')+'\n');
  calls.push(helper+'_branch_'+i+'('+captures.map(b=>b.name).join(', ')+')');audit.push({row:i,originalBodySha256:sha(text),captures:captures.map(b=>({name:b.name,quantity:b.quantity.$,type:show(b.type)}))});
 }
 const tokenName=sig.parameters[0]![1],data='type '+action+' is Data:\n'+body.r.map((_,i)=>'  '+action+'Row'+i+'{}').join('\n')+'\n\n',selector='def '+helper+'_action('+tokenName+': Lexer.Token) -> '+action+':\n  match '+tokenName+':\n'+body.r.map((r,i)=>'    case '+r.p.map(p=>source.slice(p.s!.beg,p.s!.end)).join(' ')+':\n      '+action+'Row'+i+'{}\n').join('')+'\n';
 const run='def '+helper+'_run(action: '+action+', '+sig.parameters.map(p=>(p[0].$==='Many'?'+':'')+p[1]+': '+show(p[3])).join(', ')+') -> '+show(sig.result)+':\n  match action:\n'+calls.map((call,i)=>'    case '+action+'Row'+i+'{}:\n      '+call+'\n').join('')+'\n';
 const replacement='  '+helper+'_run('+helper+'_action('+tokenName+'), '+sig.parameters.map(p=>p[1]).join(', ')+')\n\n',prefix=data+selector+helpers.join('\n')+'\n'+run,insert=source.indexOf('def '+name+'(');
 let changed=source.slice(0,begin)+replacement+source.slice(end);changed=changed.slice(0,insert)+prefix+changed.slice(insert);
 if(changed.replace(prefix,'').replace(replacement,original)!==source)throw Error('Typed do inverse differs');
 const fresh=await readParserGraph(changed);return{source:changed,graph:fresh,audit:{originalSha256:sha(source),transformedSha256:sha(changed),exactInverse:true,externalABIUnchanged:true,grammarCopiedOnly:true,branches:audit}};
}
