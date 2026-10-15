import {readParserGraph} from './parser_full_graph.ts';
import {createHash} from 'node:crypto';
const sha=(s:string)=>createHash('sha256').update(s).digest('hex');
export async function extractOperatorKeyShape(source:string){
 const original='def map_operator_key(namespace: String, key: String) -> String:\n',insert=source.indexOf(original),next=source.indexOf('\ndef ',insert+original.length),end=next<0?source.length:next+1;
 if(insert<0||end<=insert)throw Error('Operator helper source shape drift');
 const body=source.slice(insert+original.length,end),before=await readParserGraph(source),match=before.bodies.get('map_operator_key');
 if(match?.$!=='Match'||match.r.length!==15||match.r.some(r=>r.f.$==='Local'||r.f.$==='Match'))throw Error('Operator row priority drift');
 const rows=match.r.map((r,i)=>{if(r.f.$==='Local'||r.f.$==='Match')throw Error('Operator branch body drift');const expression=source.slice(r.f.s!.beg,r.f.s!.end);if(expression.replace(/\s/g,'')!==(i<14?'String.append(namespace,key)':'key'))throw Error('Operator branch body drift');return{pattern:r.p.map(p=>source.slice(p.s!.beg,p.s!.end)).join(' '),mapped:i<14};});
 const helper=rows.slice(0,14).map((r,i)=>'def operator_key_choice_'+i+'(mapped: Bool, key: String, namespace: String) -> String:\n  match mapped:\n    case True{}:\n      String.append(namespace, key)\n    case False{}:\n      '+(i===13?'key':'operator_key_test_'+(i+1)+'(key, namespace)')+'\n\n'+
 'def operator_key_test_'+i+'(+key: String, namespace: String) -> String:\n  operator_key_choice_'+i+'(String.eq(key, '+r.pattern+'), key, namespace)\n\n').reverse().join(''),replacement=original+'  operator_key_test_0(key, namespace)\n\n';
 const changed=source.slice(0,insert)+helper+replacement+source.slice(end);
 if(changed.replace(helper,'').replace(replacement,original+body)!==source)throw Error('Operator helper inverse differs');
 const graph=await readParserGraph(changed);return{source:changed,graph,audit:{originalSha256:sha(source),transformedSha256:sha(changed),exactInverse:true,externalABIUnchanged:true,originalBodySha256:sha(body),rows,orderedShortCircuitEquality:true,noTupleOrStringCopy:true,grammarCopiedOnly:true}};
}
