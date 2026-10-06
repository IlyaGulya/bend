import {readParserGraph} from './parser_full_graph.ts';
import {createHash} from 'node:crypto';
const sha=(s:string)=>createHash('sha256').update(s).digest('hex');
export async function extractOperatorKeyShape(source:string){
 const original='def map_operator_key(namespace: String, key: String) -> String:\n',insert=source.indexOf(original),end=source.indexOf('\ndef ',insert+original.length)+1;
 if(insert<0||end<=insert)throw Error('Operator helper source shape drift');
 const body=source.slice(insert+original.length,end),before=await readParserGraph(source),match=before.bodies.get('map_operator_key');
 if(match?.$!=='Match'||match.r.length!==15||match.r.some(r=>r.f.$!=='Reply'))throw Error('Operator row priority drift');
 const rows=match.r.map((r,i)=>{const expression=source.slice(r.f.$==='Reply'?r.f.x.s!.beg:0,r.f.$==='Reply'?r.f.x.s!.end:0);if(expression.replace(/\s/g,'')!==(i<14?'String.append(namespace,key)':'key'))throw Error('Operator branch body drift');return{pattern:r.p.map(p=>source.slice(p.s!.beg,p.s!.end)).join(' '),mapped:i<14};});
 const helper='def operator_key_classify(key: String) -> Bool & String:\n  match key:\n'+rows.map(r=>'    case '+r.pattern+':\n      ('+(r.mapped?'True{}':'False{}')+', key)\n').join('')+'\n'+
 'def operator_key_apply(mapped: Bool, namespace: String, key: String) -> String:\n  match mapped:\n    case True{}:\n      String.append(namespace, key)\n    case False{}:\n      key\n\n'+
 'def operator_key_result(result: Bool & String, namespace: String) -> String:\n  match result:\n    case (mapped, key):\n      operator_key_apply(mapped, namespace, key)\n\n',replacement=original+'  operator_key_result(operator_key_classify(key), namespace)\n\n';
 const changed=source.slice(0,insert)+helper+replacement+source.slice(end);
 if(changed.replace(helper,'').replace(replacement,original+body)!==source)throw Error('Operator helper inverse differs');
 const graph=await readParserGraph(changed);return{source:changed,graph,audit:{originalSha256:sha(source),transformedSha256:sha(changed),exactInverse:true,externalABIUnchanged:true,originalBodySha256:sha(body),rows,stateFreeClassifier:true,keyTransferredOnce:true,grammarCopiedOnly:true}};
}
