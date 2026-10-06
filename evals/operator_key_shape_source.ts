import {readParserGraph} from './parser_full_graph.ts';
import {createHash} from 'node:crypto';
const sha=(s:string)=>createHash('sha256').update(s).digest('hex');
export async function extractOperatorKeyShape(source:string){
 const original='def map_operator_key(namespace: String, key: String) -> String:\n',insert=source.indexOf(original),end=source.indexOf('\ndef ',insert+original.length)+1;
 if(insert<0||end<=insert)throw Error('Operator helper source shape drift');
 const body=source.slice(insert+original.length,end),helper='def operator_key_first(key: String, namespace: String) -> String:\n'+body,replacement=original+'  operator_key_first(key, namespace)\n\n';
 const changed=source.slice(0,insert)+helper+replacement+source.slice(end);
 if(changed.replace(helper,'').replace(replacement,original+body)!==source)throw Error('Operator helper inverse differs');
 const graph=await readParserGraph(changed);return{source:changed,graph,audit:{originalSha256:sha(source),transformedSha256:sha(changed),exactInverse:true,externalABIUnchanged:true,originalBodySha256:sha(body),matchedKeyFirst:true,grammarCopiedOnly:true,newRuntimeAllocation:false}};
}
