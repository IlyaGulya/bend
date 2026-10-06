import {readParserGraph} from './parser_full_graph.ts';
import {createHash} from 'node:crypto';
const sha=(s:string)=>createHash('sha256').update(s).digest('hex');
export async function extractSymbolPairShape(source:string){
 const before=await readParserGraph(source),body=before.bodies.get('multi_symbol_2'),header='def multi_symbol_2(text: String) -> SymbolPairClass:\n',start=source.indexOf(header),next=source.indexOf('\ndef ',start+header.length),end=next<0?source.length:next+1;
 if(body?.$!=='Match'||body.r.length!==15||start<0||source.includes('def symbol_pair_test_'))throw Error('Symbol pair classifier shape drift');
 const rows=body.r.map((row,i)=>{if(row.f.$!=='Reply')throw Error('Symbol pair branch drift');const pattern=row.p.map(p=>source.slice(p.s!.beg,p.s!.end)).join(' '),expression=source.slice(row.f.x.s!.beg,row.f.x.s!.end);if(i<13){const text=JSON.parse(pattern);if(typeof text!=='string'||expression.replace(/\s/g,'')!=='SymbolPairMerged{'+JSON.stringify(text)+'}')throw Error('Symbol pair literal output drift');}return{pattern,expression};});
 const fallback='def symbol_pair_fallback(text: String) -> SymbolPairClass:\n  match text:\n'+rows.slice(13).map(r=>'    case '+r.pattern+':\n      '+r.expression+'\n').join('')+'\n';
 const helpers=rows.slice(0,13).map((r,i)=>'def symbol_pair_choice_'+i+'(matched: Bool, text: String) -> SymbolPairClass:\n  match matched:\n    case True{}:\n      '+r.expression+'\n    case False{}:\n      '+(i===12?'symbol_pair_fallback(text)':'symbol_pair_test_'+(i+1)+'(text)')+'\n\n'+
 'def symbol_pair_test_'+i+'(+text: String) -> SymbolPairClass:\n  symbol_pair_choice_'+i+'(String.eq(text, '+r.pattern+'), text)\n\n').reverse().join('');
 const original=source.slice(start,end),replacement=fallback+helpers+header+'  symbol_pair_test_0(text)\n\n',changed=source.slice(0,start)+replacement+source.slice(end);
 if(changed.slice(0,start)+original+changed.slice(start+replacement.length)!==source)throw Error('Symbol pair source inverse differs');
 const graph=await readParserGraph(changed);return{source:changed,graph,audit:{originalSha256:sha(source),transformedSha256:sha(changed),exactInverse:true,externalABIUnchanged:true,rows,orderedShortCircuitEquality:true,originalFallbackCopiedExactly:true,noTupleOrStringCopy:true}};
}
