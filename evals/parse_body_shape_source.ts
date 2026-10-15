import * as B from '../bend2/bend.ts';
import {readParserGraph} from './parser_full_graph.ts';
import {LexicalTypes} from './parser_full_type_env.ts';
import {lexicalBodyCaptures,captureQuantityPrefix} from './parser_full_lexical_body_capture.ts';
import {createHash} from 'node:crypto';
const sha=(s:string)=>createHash('sha256').update(s).digest('hex');
const showType=(t:B.LTerm)=>B.term_show(t).replace(/\bast\./g,'Ast.').replace(/\blexer\./g,'Lexer.');
export async function extractBodyShape(source:string){
 const graph=await readParserGraph(source),body=graph.bodies.get('parse_body_scan'),sig=graph.signatures.get('parse_body_scan');
 if(body?.$!=='Match'||body.r.length!==2||body.r[0]!.f.$!=='Match'||!sig)throw Error('Body scanner shape drift');
 const tokenMatch=body.r[0]!.f;
 const nameRows=[...tokenMatch.r.entries()].filter(([,row])=>row.f.$==='Match');
 if(nameRows.length!==1)throw Error('Body name row shape drift');
 const[nameRowIndex,nameRow]=nameRows[0]!,restMatch=nameRow.f;
 if(restMatch.$!=='Match'||restMatch.r.length!==2||restMatch.r[0]!.f.$!=='Match')throw Error('Body name/rest shape drift');
 const nextMatch=restMatch.r[0]!.f;if(nextMatch.r.length!==4)throw Error('Body next-token priority drift');
 const types=new LexicalTypes(graph.parserBook,graph.signatures);types.indexBody(body,sig.parameters,sig.result);
 const helpers:string[]=[],audit:object[]=[];
 const line=(offset:number)=>source.lastIndexOf('\n',offset)+1;
 const rowBegin=(row:B.Case)=>source.indexOf('\n',source.indexOf(':',Math.max(...row.p.map(p=>p.s!.end))))+1;
 type Patch={beg:number,end:number,after:string};
 function helper(b:B.Body,beg:number,end:number,name:string,children:Patch[]=[]){
  const captured=lexicalBodyCaptures(b,types);
  const original=source.slice(beg,end);let rendered=original;
  for(const patch of [...children].sort((a,b)=>b.beg-a.beg)){if(patch.beg<beg||patch.end>end)throw Error('Nested body helper range escaped');rendered=rendered.slice(0,patch.beg-beg)+patch.after+rendered.slice(patch.end-beg);}
  const indentation=original.match(/^ */)![0].length,lines=rendered.trimEnd().split('\n');if(lines.some(s=>s.trim()&&!s.startsWith(' '.repeat(indentation))))throw Error('Body helper indentation drift');
  helpers.push('def '+name+'('+captured.map(b=>captureQuantityPrefix(b.quantity)+b.name+': '+showType(b.type)).join(', ')+') -> '+showType(sig.result)+':\n'+lines.map(s=>s.trim()?'  '+s.slice(indentation):'').join('\n')+'\n');
  const call=' '.repeat(indentation)+name+'('+captured.map(b=>b.name).join(', ')+')\n';
  audit.push({helper:name,originalBodySha256:sha(original),captured:captured.map(b=>({id:b.id,name:b.name,quantity:b.quantity.$,type:showType(b.type)})),captureOrder:'type dependencies then source binder ID',grammarCopiedOnly:true});
  return{beg,end,after:call};
 }
 const nextEnd=line(restMatch.r[1]!.p[0]!.s!.beg),nextBegin=line(nextMatch.e[0]!.s!.beg),nextRows:Patch[]=[];
 for(const [i,row]of nextMatch.r.entries())nextRows.push(helper(row.f,rowBegin(row),i+1<nextMatch.r.length?line(nextMatch.r[i+1]!.p[0]!.s!.beg):nextEnd,'parse_body_next_row_'+i));
 const nextPatch=helper(nextMatch,nextBegin,nextEnd,'parse_body_next_dispatch',nextRows);
 const tokenEnd=line(body.r[1]!.p[0]!.s!.beg),tokenRows:Patch[]=[];
 for(const [i,row]of tokenMatch.r.entries())tokenRows.push(helper(row.f,rowBegin(row),i+1<tokenMatch.r.length?line(tokenMatch.r[i+1]!.p[0]!.s!.beg):tokenEnd,'parse_body_token_row_'+i,i===nameRowIndex?[nextPatch]:[]));
 let changed=source;for(const p of [...tokenRows].sort((a,b)=>b.beg-a.beg))changed=changed.slice(0,p.beg)+p.after+changed.slice(p.end);
 const insert=source.indexOf('def parse_body_scan('),prefix=helpers.join('\n')+'\n';changed=changed.slice(0,insert)+prefix+changed.slice(insert);
 let inverse=changed.replace(prefix,'');for(const p of tokenRows){if(inverse.split(p.after).length!==2)throw Error('Nonunique body helper call');inverse=inverse.replace(p.after,source.slice(p.beg,p.end));}if(inverse!==source)throw Error('Body extraction inverse differs');
 const beforeControl=changed;
 const rootBegin=changed.indexOf('      match token:\n',changed.indexOf('def parse_body_scan(')),rootEnd=changed.indexOf('    case Nil{}:',rootBegin),originalRoot=changed.slice(rootBegin,rootEnd);
 if(rootBegin<0||rootEnd<0)throw Error('Body root dispatch range drift');
 const actionType='type BodyScanAction is Data:\n'+tokenMatch.r.map((_,i)=>'  BodyScanActionRow'+i+'{}').join('\n')+'\n\n';
 const selector='def body_scan_action(token: Lexer.Token) -> BodyScanAction:\n  match token:\n'+tokenMatch.r.map((row,i)=>'    case '+row.p.map(p=>source.slice(p.s!.beg,p.s!.end)).join(' ')+':\n      BodyScanActionRow'+i+'{}\n').join('')+'\n';
 const run='def body_scan_run(+token: Lexer.Token, action: BodyScanAction, file: String, tokens: List<&2, Lexer.Token>, +rest: List<&2, Lexer.Token>, scope: List<&2, Scope>, depth: Nat, parent_col: Nat) -> '+showType(sig.result)+':\n  match token:\n    case Lexer.TokenInfo{_, key, beg, end, _, col}:\n      match action:\n'+tokenRows.map((p,i)=>'        case BodyScanActionRow'+i+'{}:\n          '+p.after.trim()+'\n').join('')+'\n';
 const dispatch='      body_scan_run(token, body_scan_action(token), file, tokens, rest, scope, depth, parent_col)\n',control=actionType+selector+run;
 changed=changed.slice(0,rootBegin)+dispatch+changed.slice(rootEnd);const controlAt=changed.indexOf('def parse_body_scan(');changed=changed.slice(0,controlAt)+control+changed.slice(controlAt);
 if(changed.replace(control,'').replace(dispatch,originalRoot)!==beforeControl)throw Error('Body action factoring inverse differs');
 const fresh=await readParserGraph(changed),before=sig.parameters.map(p=>[p[0].$,p[1],showType(p[3])]),after=fresh.signatures.get('parse_body_scan')!.parameters.map(p=>[p[0].$,p[1],showType(p[3])]);if(JSON.stringify(before)!==JSON.stringify(after))throw Error('Body external ABI changed');
 return{source:changed,graph:fresh,audit:{originalSha256:sha(source),transformedSha256:sha(changed),externalBodyABIUnchanged:true,exactInverse:true,originalRows:{tokens:tokenMatch.r.length,nameRest:restMatch.r.length,nextToken:nextMatch.r.length},helpers:audit,newUnsafe:false,sourceSpecificGeneratorExceptions:0}};
}
