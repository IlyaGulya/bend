import {readParserGraph} from './parser_full_graph.ts';
import {createHash} from 'node:crypto';
const sha=(s:string)=>createHash('sha256').update(s).digest('hex');
export async function extractExternalImportShape(source:string){
 const before=await readParserGraph(source),body=before.bodies.get('parse_external_imports_scan');
 if(body?.$!=='Match'||body.r.length!==2||body.r[0]!.f.$!=='Match'||body.r[0]!.f.r.length!==3)throw Error('External import matrix drift');
 const nested=body.r[0]!.f,line=(n:number)=>source.lastIndexOf('\n',n)+1,start=source.indexOf('def parse_external_imports_scan('),begin=line(body.e[0]!.s!.beg),next=source.indexOf('\ndef ',start),end=next+1,original=source.slice(start,end),originalBody=source.slice(begin,end);
 if(start<0||next<0)throw Error('External import source range drift');
 const replacements=[
  ['parse_external_imports_scan(rest, original, acc)', 'external_import_worker(rest, original, acc, external_import_action(rest))'],
  ['parse_external_imports_scan(after_path, after_path, strip_quotes(text) <> acc)', 'external_import_worker(after_path, after_path, strip_quotes(text) <> acc, external_import_action(after_path))']
 ] as const;
 const patterns=nested.r.map(r=>r.p.map(p=>source.slice(p.s!.beg,p.s!.end)).join(' ')),nilBegin=line(body.r[1]!.p[0]!.s!.beg);
 const branches=nested.r.map((row,i)=>{
  const beg=source.indexOf('\n',source.indexOf(':',Math.max(...row.p.map(p=>p.s!.end))))+1,finish=i+1<nested.r.length?line(nested.r[i+1]!.p[0]!.s!.beg):nilBegin,text=source.slice(beg,finish),indent=text.match(/^ */)![0].length;
  return '    case '+(i<2?'+token <> +rest '+i+'n':'_ <> _ _')+':\n'+text.trimEnd().split('\n').map(s=>s.trim()?'      '+s.slice(indent):'').join('\n')+'\n';
 });
 let workerBody='  match current action:\n'+branches.join('')+source.slice(nilBegin,end).replace('case Nil{}:','case Nil{} _:');
 for(const [a,b]of replacements){if(workerBody.split(a).length!==2)throw Error('External worker rewrite anchor drift');workerBody=workerBody.replace(a,b);}
 const predicate='def external_import_token_action(token: Lexer.Token) -> Nat:\n  match token:\n'+patterns.map((p,i)=>'    case '+p+':\n      '+i+'n\n').join('')+'\n'+
 'def external_import_action(current: List<&2, Lexer.Token>) -> Nat:\n  match current:\n    case +token <> _:\n      external_import_token_action(token)\n    case Nil{}:\n      2n\n\n';
 const result='(List<&2, String> & List<&2, Lexer.Token>) & Bool',worker='def external_import_worker(+current: List<&2, Lexer.Token>, original: List<&2, Lexer.Token>, acc: List<&2, String>, action: Nat) -> '+result+':\n'+workerBody,
 initial='def external_import_start(+current: List<&2, Lexer.Token>, original: List<&2, Lexer.Token>, acc: List<&2, String>) -> '+result+':\n  external_import_worker(current, original, acc, external_import_action(current))\n\n',wrapper=source.slice(start,begin)+'  external_import_start(current, original, acc)\n\n',replacement=predicate+worker+initial+wrapper,changed=source.slice(0,start)+replacement+source.slice(end);
 if(changed.slice(0,start)+original+changed.slice(start+replacement.length)!==source)throw Error('External worker source inverse differs');
 const graph=await readParserGraph(changed);return{source:changed,graph,audit:{originalSha256:sha(source),transformedSha256:sha(changed),exactInverse:true,externalABIUnchanged:true,originalBodySha256:sha(originalBody),patterns,recursiveSuffixes:['rest','after_path'],actionUpdatedOnlyAfterShrink:true,newMutualRecursion:false,internalReusableTokenBindings:['current','rest'],ownedStateQuantitiesUnchanged:['original','acc'],noUnsafe:true}};
}
