import * as B from '../bend2/bend.ts';
import {readParserGraph} from './parser_full_graph.ts';
import {LexicalTypes,freeBinderIds} from './parser_full_type_env.ts';
import {createHash} from 'node:crypto';
const sha=(s:string)=>createHash('sha256').update(s).digest('hex');
const showType=(t:B.LTerm)=>B.term_show(t).replace(/\bast\./g,'Ast.').replace(/\blexer\./g,'Lexer.');
export async function extractAtomShape(source:string){
 const graph=await readParserGraph(source),body=graph.bodies.get('parse_atom_scan'),sig=graph.signatures.get('parse_atom_scan');
 if(body?.$!=='Match'||body.r.length!==2||body.r[0]!.f.$!=='Match'||!sig)throw Error('Atom scanner shape drift');
 const tokens=body.r[0]!.f;
 if(tokens.r.length!==6)throw Error('Atom token dispatch priority drift');
 const types=new LexicalTypes(graph.parserBook,graph.signatures);types.indexBody(body,sig.parameters,sig.result);
 const insert=source.indexOf('def parse_atom_scan('),patches:{beg:number,end:number,after:string}[]=[],helpers:string[]=[],audit:object[]=[];
 for(const [index,name,count] of [[0,'parse_atom_name_dispatch',6],[2,'parse_atom_symbol_dispatch',11]] as const){
  const match=tokens.r[index]!.f;
  if(match.$!=='Match'||match.e.length!==1||match.r.length!==count||match.e[0]!.$!=='Var')throw Error('Atom scalar dispatch drift '+name);
  const scalar=match.e[0]!,env=types.environmentAt(scalar),ids=new Set<number>();
  function expr(t:B.LTerm){for(const id of freeBinderIds(t))if(env.has(id))ids.add(id);}
  function visit(b:B.Body){if(b.$==='Reply')expr(b.x);else if(b.$==='Local'){b.v.forEach(expr);visit(b.f);}else{b.e.forEach(expr);b.r.forEach(r=>visit(r.f));}}visit(match);
  const ordered=[scalar.i,...[...ids].filter(id=>id!==scalar.i).sort((a,b)=>a-b)];
  const captured=ordered.map(id=>{const binding=env.get(id);if(!binding)throw Error('Unknown helper capture '+id);return binding;});
  const begin=source.lastIndexOf('\n',scalar.s!.beg)+1,next=tokens.r[index+1]!.p[0]!;
  const end=source.lastIndexOf('\n',next.s!.beg)+1,original=source.slice(begin,end);
  const lines=original.trimEnd().split('\n');if(lines.some(line=>line.trim()&&!line.startsWith('          ')))throw Error('Atom Body indentation drift');
  const rendered=lines.map(line=>line.trim()?'  '+line.slice(10):'').join('\n');
  const parameters=captured.map(b=>(b.quantity.$==='Many'?'+':'')+b.name+': '+showType(b.type)),actuals=captured.map(b=>b.name);
  helpers.push('def '+name+'('+parameters.join(', ')+') -> '+showType(sig.result)+':\n'+rendered+'\n');
  const call='          '+name+'('+actuals.join(', ')+')\n';patches.push({beg:begin,end,after:call});
  audit.push({helper:name,originalRows:match.r.length,patterns:match.r.map(row=>row.p.map(p=>source.slice(p.s!.beg,p.s!.end))),captured:captured.map((b,i)=>({id:ordered[i],name:b.name,quantity:b.quantity.$,type:showType(b.type)})),sourceBodySha256:sha(original),matchedScalarFirst:true,recursiveLogicUnchanged:true});
 }
 let changed=source;for(const p of [...patches].sort((a,b)=>b.beg-a.beg))changed=changed.slice(0,p.beg)+p.after+changed.slice(p.end);
 changed=changed.slice(0,insert)+helpers.join('\n')+'\n'+changed.slice(insert);
 let inverse=changed.replace(helpers.join('\n')+'\n','');for(const p of patches){if(inverse.split(p.after).length!==2)throw Error('Nonunique extraction call');inverse=inverse.replace(p.after,source.slice(p.beg,p.end));}if(inverse!==source)throw Error('Non-invertible atom extraction');
 const fresh=await readParserGraph(changed);
 const before=sig.parameters.map(p=>[p[0].$,p[1],showType(p[3])]),after=fresh.signatures.get('parse_atom_scan')!.parameters.map(p=>[p[0].$,p[1],showType(p[3])]);if(JSON.stringify(before)!==JSON.stringify(after))throw Error('External atom ABI changed');
 return{source:changed,graph:fresh,audit:{originalSha256:sha(source),transformedSha256:sha(changed),externalAtomABIUnchanged:true,exactInverse:true,helpers:audit,grammarLogicCopiedOnly:true,newUnsafe:false}};
}
